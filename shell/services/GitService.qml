pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Wraps SocketService's generic module/action/payload protocol for the
// daemon's "git" module. Keyed by repo path (statusByRepo/errorByRepo)
// rather than a single flat "current status" — a response arriving for
// a DIFFERENT repo than the one you're currently looking at (e.g. you
// switched away and the daemon's answer was already in flight) should
// never overwrite what you're actually viewing.
Singleton {
    id: root

    property var statusByRepo: ({})   // repoPath -> {branch, ahead, behind, staged, unstaged, untracked}
    property var errorByRepo: ({})    // repoPath -> {action, message}

    // Was a single flat `loading: bool` — set true by ANY _send() call
    // and false by ANY response, regardless of which repo either
    // belonged to. With two repos open and requests in flight for
    // both, the first one to respond incorrectly cleared loading for
    // the OTHER repo's still-pending request too. Per-repo, per-action
    // tracking instead — repoPath -> action string ("push"/"pull"/
    // "commit"/"stage"/"unstage"/"status"), absent/undefined if
    // nothing's pending for that repo.
    property var pendingActionByRepo: ({})

    // Backward-compatible aggregate — true if ANYTHING is pending
    // anywhere, for any existing UI that just wants a single "is git
    // doing something right now" signal rather than per-repo detail.
    readonly property bool loading: Object.keys(pendingActionByRepo).length > 0

    // What callers actually want for a specific button (e.g. "is push
    // in flight for THIS repo") — the whole point of this refactor.
    function isPending(repo, action) {
        return root.pendingActionByRepo[repo] === action;
    }
    function isRepoBusy(repo) {
        return root.pendingActionByRepo.hasOwnProperty(repo);
    }

    signal statusUpdated(string repo)
    signal errorOccurred(string repo, string action, string message)

    function _setPending(repo, action) {
        const copy = Object.assign({}, root.pendingActionByRepo);
        copy[repo] = action;
        root.pendingActionByRepo = copy;
        root.pendingStartTimeByRepo[repo] = Date.now();
    }
    function _clearPending(repo) {
        if (!root.pendingActionByRepo.hasOwnProperty(repo))
            return;
        const copy = Object.assign({}, root.pendingActionByRepo);
        delete copy[repo];
        root.pendingActionByRepo = copy;
        delete root.pendingStartTimeByRepo[repo];
    }

    Connections {
        target: SocketService
        function onMessageReceived(type, payload) {
            if (type === "git_status") {

                const repo = payload.repo;
                const copy = Object.assign({}, root.statusByRepo);
                copy[repo] = payload;
                root.statusByRepo = copy;
                // A fresh, successful status supersedes any earlier
                // error shown for this same repo.
                if (root.errorByRepo[repo]) {
                    const errCopy = Object.assign({}, root.errorByRepo);
                    delete errCopy[repo];
                    root.errorByRepo = errCopy;
                }
                root._clearPending(repo);
                root.statusUpdated(repo);
            } else if (type === "git_error") {
                const repo = payload.repo;
                const errCopy = Object.assign({}, root.errorByRepo);
                errCopy[repo] = {
                    action: payload.action,
                    message: payload.message
                };
                root.errorByRepo = errCopy;
                root._clearPending(repo);
                root.errorOccurred(repo, payload.action, payload.message);
            }
        }
    }

    // Client-side safety net — the daemon already bounds push/pull to
    // 15s and everything else to 10s (see git_manager.py), guaranteeing
    // SOME response eventually IF the request actually reaches it and
    // the daemon is alive. This covers the remaining gap: the socket
    // disconnecting mid-request, or the request never making it there
    // at all — without this, a pending entry would just sit there
    // forever with nothing telling you anything went wrong.
    //
    // A single sweep timer checking every pending repo's own start
    // timestamp — not one Timer per request (QML doesn't make
    // dynamically creating/destroying named Timer instances pleasant)
    // — running only while there's actually something to watch.
    property var pendingStartTimeByRepo: ({})
    readonly property int _timeoutMs: 20000
    property Timer _timeoutSweepTimer: Timer {
        interval: 1000
        repeat: true
        running: Object.keys(root.pendingStartTimeByRepo).length > 0
        onTriggered: {
            const now = Date.now();
            for (const repo in root.pendingStartTimeByRepo) {
                if (now - root.pendingStartTimeByRepo[repo] > root._timeoutMs) {
                    const action = root.pendingActionByRepo[repo];
                    root._clearPending(repo);
                    root.errorOccurred(repo, action, "No response from daemon (timed out) — check the daemon is running.");
                }
            }
        }
    }

    function _send(action, repo, extraPayload) {
        root._setPending(repo, action);
        const payload = Object.assign({
            repo: repo
        }, extraPayload ?? {});
        SocketService.sendCommand("git", action, payload);
    }

    function requestStatus(repo) {
        root._send("status", repo);
    }
    function stage(repo, files) {
        root._send("stage", repo, {
            files: files ?? []
        });
    }
    function unstage(repo, files) {
        root._send("unstage", repo, {
            files: files ?? []
        });
    }
    function commit(repo, message) {
        root._send("commit", repo, {
            message: message
        });
    }
    function push(repo) {
        root._send("push", repo);
    }
    function pull(repo) {
        root._send("pull", repo);
    }

    function statusFor(repo) {
        return root.statusByRepo[repo] ?? null;
    }
    function errorFor(repo) {
        return root.errorByRepo[repo] ?? null;
    }
}
