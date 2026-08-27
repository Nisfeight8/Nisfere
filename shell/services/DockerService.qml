pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ==========================================
    // SIGNALS
    // ==========================================
    signal dataRefreshed
    signal navigateToDetails

    // Fired ONLY from the daemon's explicit "action_result" message —
    // one specific container/image/volume/compose action just settled
    // (succeeded or failed). This is the ONLY reliable way to know a
    // particular action has finished: the daemon also broadcasts plain
    // docker_stats on its own periodic poll cycle (see Dashboard.qml's
    // 3s timer), completely independent of whether some action is still
    // running — so an unrelated docker_stats can arrive WHILE your
    // action is still in flight and would be indistinguishable from a
    // real completion if you tried to infer "done" from it. This signal
    // carries actionType/action/target so listeners can match it to the
    // specific action THEY triggered and ignore everything else.
    //
    // `target` is deliberately `var`, NOT `string`: container/image/
    // volume actions send a plain id string, but compose actions send
    // (and this echoes back) an OBJECT ({working_dir: ...}) — a `string`
    // parameter here would silently coerce that object to something
    // like "[object Object]" when the signal fires, permanently
    // breaking every listener's `target.working_dir` check for compose
    // actions specifically (they'd never match, so their spinners would
    // never clear) while container/image/volume actions kept working
    // fine — exactly the asymmetric bug this caused.
    signal actionResult(string actionType, string action, var target, bool success)

    // ==========================================
    // GLOBAL STATE PROPERTIES
    // ==========================================
    property var composeProjects: ({})
    property var standaloneContainers: []
    property int runningContainers: 0
    property int totalContainers: 0

    property var dockerImages: []
    property var dockerVolumes: []

    // Structural/connection-level issue reported ALONGSIDE a
    // docker_stats payload (e.g. "Docker is not installed") — separate
    // from lastActionError below, which is about one specific action
    // failing, not the whole stats fetch.
    property string errorMessage: ""

    // True from requestDockerStats() until the next docker_stats
    // message arrives (or the timeout below gives up waiting). Lets
    // any UI reading this (e.g. the @containers search provider) show
    // a real loading state on first fetch instead of a misleading
    // "nothing found". Deliberately scoped to JUST the stats-fetch
    // lifecycle, not actions — see actionPending below for that.
    property bool loading: false

    // True while ANY container/image/volume/compose action (anything
    // routed through _dockerAction) is in flight, cleared ONLY by the
    // matching actionResult signal above — never by a plain docker_stats
    // or generic error, since either of those can legitimately arrive
    // from an unrelated periodic poll while a real action is still
    // running (see actionResult's comment). If you need to track a
    // SPECIFIC action (e.g. only show a spinner on the row/tab that
    // triggered it), listen to actionResult directly instead of this —
    // this flag just answers "is *something* pending right now".
    property bool actionPending: false

    // A specific action (start/stop/restart/delete/...) failed — the
    // daemon's generic {"type": "error", "payload": {"action", "error"}}
    // message. Kept for the error BANNER text (still useful even though
    // actionPending/actionResult no longer depend on it) — cleared
    // automatically the next time a docker_stats arrives (a fresh
    // successful stats fetch means whatever failed is now stale news).
    property string lastActionError: ""
    property string lastActionErrorAction: ""

    // Client-side safety net — mirrors GitService's own timeout. The
    // daemon already always responds to get_stats (even the failure
    // path returns a docker_stats payload with its own error field —
    // see docker_service.py's get_docker_status), so this only
    // matters if the socket itself drops mid-request; without it,
    // `loading` would stay true forever with nothing telling you
    // anything went wrong.
    readonly property int _requestTimeoutMs: 10000
    property Timer _requestTimeoutTimer: Timer {
        interval: root._requestTimeoutMs
        onTriggered: {
            root.loading = false;
            root.errorMessage = "No response from daemon (timed out) — check the daemon is running.";
        }
    }

    // Same safety-net idea, but for actionPending — the daemon now
    // ALWAYS sends an action_result for every action (success path AND
    // the exception path, see docker_manager.py), so this only matters
    // if the socket itself drops mid-action. Its own separate timer:
    // an action and a periodic stats poll can legitimately be in flight
    // at the same time and shouldn't reset each other's deadline.
    readonly property int _actionTimeoutMs: 10000
    property Timer _actionTimeoutTimer: Timer {
        interval: root._actionTimeoutMs
        onTriggered: {
            root.actionPending = false;
        }
    }

    // ==========================================
    // CONTAINER DETAILS STATE
    // ==========================================
    property var activeContainerDetails: null
    property bool isViewingDetails: false

    // Which container's details we're actually waiting on right now —
    // guards against a slow/delayed response for a PREVIOUS
    // inspectContainer() call landing after you've already navigated
    // to a different container, which would otherwise silently
    // overwrite activeContainerDetails with stale data for the wrong
    // container.
    property string _expectedDetailsContainerId: ""

    // ==========================================
    // LIVE STREAMING STATE
    // ==========================================
    property string streamingContainerId: ""
    property string liveCpu: "0%"
    property string liveRam: "0B"
    property string liveLogs: ""

    // ==========================================
    // SOCKET MESSAGE ROUTER
    // ==========================================
    property Connections _conn: Connections {
        target: SocketService

        function onMessageReceived(type, payload) {
            if (type === "docker_stats") {
                root._requestTimeoutTimer.stop();
                root.loading = false;

                // 1. Update general container data
                root.runningContainers = payload.runningCount ?? 0;
                root.totalContainers = payload.totalCount ?? 0;
                root.composeProjects = payload.composeProjects ?? {};
                root.standaloneContainers = payload.standaloneContainers ?? [];

                // 2. Update new tabs data (Images & Volumes)
                root.dockerImages = payload.images ?? [];
                root.dockerVolumes = payload.volumes ?? [];

                root.errorMessage = payload.error ?? "";

                // 3. Auto-refresh details if the user is actively viewing a container
                if (root.activeContainerDetails && root.isViewingDetails) {
                    root.inspectContainer(root.activeContainerDetails.id);
                }

                root.dataRefreshed();
            } else if (type === "action_result") {
                // The one authoritative "this action just finished"
                // signal — see actionResult's own comment above for why
                // this can't be inferred from docker_stats/error alone.
                root._actionTimeoutTimer.stop();
                root.actionPending = false;
                root.actionResult(payload.action_type ?? "", payload.action ?? "", payload.target ?? "", payload.success ?? false);
            } else if (type === "container_details") {
                if (payload.id !== root._expectedDetailsContainerId)
                    return; // stale — superseded by a newer inspectContainer() call
                root.activeContainerDetails = payload;
                root.dataRefreshed();
            } else if (type === "stream_log") {
                root.liveLogs += payload;
            } else if (type === "stream_stat") {
                root.liveCpu = payload.CPUPerc;
                root.liveRam = payload.MemUsage;
            } else if (type === "error") {
                // Purely for the error banner's text now — actionPending
                // is no longer cleared here (that's action_result's job,
                // see above), since a generic "error" for an unrelated
                // module/request could otherwise clear a completely
                // different action's pending state by accident.
                root.lastActionError = payload.error ?? "Docker action failed";
                root.lastActionErrorAction = payload.action ?? "";
            }
        }
    }

    // ==========================================
    // DOCKER ACTIONS
    // ==========================================
    // Was 4 near-duplicate functions each hand-building the same
    // {action_type, target} payload shape — consolidated into one
    // private helper, same "_openFlag"-style DRY pattern already used
    // in ShellState for its own near-identical open/close/toggle
    // functions.
    function _dockerAction(actionType, action, target) {
        // The daemon now ALWAYS sends back an action_result for this
        // specific (actionType, action, target) — see docker_manager.py
        // — so it's safe to flip actionPending on here and know it'll
        // be cleared by that exact response (or the timeout, if the
        // socket itself drops), never by an unrelated periodic
        // docker_stats.
        root.actionPending = true;
        root._actionTimeoutTimer.restart();
        SocketService.sendCommand("docker", action, {
            "action_type": actionType,
            "target": target
        });
    }

    function composeAction(action, workingDir) {
        root._dockerAction("compose", action, workingDir);
    }

    function containerAction(action, containerId) {
        // Drop the "streaming shield" visually if we restart or stop
        if (action === "restart" || action === "stop") {
            root.streamingContainerId = "";
            root.liveLogs = "Waiting for container...\n";
            root.liveCpu = "0%";
            root.liveRam = "0B";
        }
        root._dockerAction("container", action, containerId);
    }

    function imageAction(action, imageId) {
        root._dockerAction("image", action, imageId);
    }

    // Removes dangling (<none>:<none>) images — daemon-side scope
    // matches plain `docker image prune`, not the more aggressive
    // `-a` variant. See docker_service.py's docker_action for the
    // reasoning.
    function pruneImages() {
        root._dockerAction("image", "prune", "");
    }

    function volumeAction(action, volumeName) {
        root._dockerAction("volume", action, volumeName);
    }

    // Same reasoning as pruneImages() — removes unused volumes,
    // matches plain `docker volume prune` scope.
    function pruneVolumes() {
        root._dockerAction("volume", "prune", "");
    }

    // ==========================================
    // NAVIGATION & DETAILS
    // ==========================================

    function inspectContainer(containerId) {
        root._expectedDetailsContainerId = containerId;
        const payload = {
            "action_type": "container",
            "target": containerId
        };
        SocketService.sendCommand("docker", "inspect_container", payload);
    }

    function requestAndNavigate(containerId) {
        root.isViewingDetails = true;
        root.inspectContainer(containerId);
        root.navigateToDetails();
    }

    // ==========================================
    // STREAM MANAGEMENT
    // ==========================================
    // Deliberately NOT wired into actionPending/either timeout: unlike
    // the request/response actions above, start_stream/stop_stream don't
    // get an action_result reply (the daemon just starts pushing
    // stream_stat/stream_log messages, or silently stops doing so) —
    // there's no single "done" event to clear a pending flag on.

    function startStream(containerId, initialLogs) {
        // Shield: Do nothing if the stream is already running for this ID
        if (root.streamingContainerId === containerId)
            return;

        root.streamingContainerId = containerId;
        root.liveLogs = initialLogs || "";
        root.liveCpu = "0%";
        root.liveRam = "0B";
        const payload = {
            "action_type": "container",
            "target": containerId
        };
        SocketService.sendCommand("docker", "start_stream", payload);
    }

    function stopStream() {
        // Shield: Do nothing if there's no stream running
        if (root.streamingContainerId === "")
            return;

        root.streamingContainerId = "";
        // No "target" here deliberately — the daemon's stop_stream
        // handler (_streams.stop_all()) stops every active stream
        // unconditionally, it doesn't look at target at all. Kept
        // action_type for consistency with every other payload shape
        // even though this specific action doesn't use it.
        const payload = {
            "action_type": "container"
        };
        SocketService.sendCommand("docker", "stop_stream", payload);
    }

    function requestDockerStats() {
        root.loading = true;
        root._requestTimeoutTimer.restart();
        SocketService.sendCommand("docker", "get_stats", {});
    }
}
