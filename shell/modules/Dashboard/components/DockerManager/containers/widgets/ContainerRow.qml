import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Rectangle {
    id: root

    property real uiScale: 1.0
    // Was `property var cd: null` — every binding below reads cd.xxx
    // immediately, which risked a transient null read during binding
    // evaluation order. required means QML guarantees a real value is
    // supplied at creation time, same convention as GitManager's
    // repoPath and SearchResultRow's modelData elsewhere in this
    // shell.
    required property var cd
    property bool isStandalone: false

    // EXPERIMENT — testing IconButton's `spinning` (RotationAnimator)
    // for real per-action loading feedback, per explicit request. This
    // shell has avoided spin/rotation elsewhere (GitManager's refresh,
    // SysMon) due to a past experience of it hanging Quickshell — if
    // that happens here too, revert to the same dim+disable pattern
    // used there instead of this block.
    //
    // Tracks WHICH action is in flight (not just a single bool) so
    // only the button you actually clicked spins, not all four at
    // once. Reset via the daemon's explicit action_result (see
    // DockerService.qml), matched to THIS container's id — not the
    // old dataRefreshed signal, which also fires from the Dashboard's
    // own independent 3s stats-poll timer and could clear this
    // prematurely while the real action was still running (see the
    // chat/DockerService.qml's actionResult comment for the full
    // reasoning).
    property string pendingAction: ""

    Connections {
        target: DockerService
        function onActionResult(actionType, action, target, success) {
            if (actionType === "container" && target === root.cd.id) {
                root.pendingAction = "";
            }
        }
    }

    function statusColor(s) {
        if (s === "running")
            return Theme.color10;
        if (s === "restarting")
            return Theme.color3;
        if (s === "paused")
            return Theme.color11;
        if (s === "created")
            return Theme.color6;
        if (s === "dead")
            return Theme.color1;
        return Theme.foregroundAlt;
    }

    border.color: cd.status === "running" ? Qt.rgba(Theme.color10.r, Theme.color10.g, Theme.color10.b, 0.25) : Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.40)
    border.width: 1
    color: Theme.backgroundAlt
    height: 42 * root.uiScale
    radius: Theme.radius
    width: parent.width

    Rectangle {
        anchors.fill: parent
        color: Theme.color4
        opacity: rowHover.hovered ? 0.07 : 0.0
        radius: parent.radius

        Behavior on opacity {
            NumberAnimation {
                duration: 80
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10 * root.uiScale
        anchors.rightMargin: 10 * root.uiScale
        spacing: 8 * root.uiScale

        // Navigate-to-details is scoped to JUST this sub-Item (status
        // dot + name/status), NOT the whole row — was a TapHandler on
        // `root` covering the entire row including the action buttons
        // below, so clicking start/stop/restart/delete ALSO triggered
        // navigation to details. Same class of bug (and same spatial-
        // separation fix) as SearchResultRow's actions vs. row-
        // activation area earlier in this shell's cleanup — TapHandler
        // doesn't automatically stop an overlapping parent-level
        // handler from also firing, so the fix is giving each its own
        // non-overlapping hit area rather than relying on event
        // propagation semantics.
        Item {
            Layout.fillWidth: true
            implicitHeight: navigableRow.implicitHeight

            RowLayout {
                id: navigableRow
                anchors.fill: parent
                spacing: 8 * root.uiScale

                Rectangle {
                    color: root.statusColor(cd.status)
                    height: 8 * root.uiScale
                    radius: height / 2
                    width: 8 * root.uiScale

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: cd.status === "running"

                        NumberAnimation {
                            duration: 950
                            easing.type: Easing.InOutSine
                            to: 0.30
                        }
                        NumberAnimation {
                            duration: 950
                            easing.type: Easing.InOutSine
                            to: 1.00
                        }
                    }
                }
                Column {
                    Layout.fillWidth: true
                    spacing: 1 * root.uiScale

                    Text {
                        color: Theme.foreground
                        elide: Text.ElideRight
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 12 * root.uiScale
                        text: (cd.service && cd.service !== "N/A") ? cd.service : cd.name
                        width: parent.width
                    }
                    Text {
                        color: root.statusColor(cd.status)
                        font.family: Theme.fontName
                        font.pixelSize: 10 * root.uiScale
                        text: cd.status
                    }
                }
            }

            HoverHandler {
                id: rowHover
                enabled: !root.isStandalone
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                enabled: !root.isStandalone
                onTapped: DockerService.requestAndNavigate(root.cd.id)
            }
        }

        // Was 4 ActionButton instances (custom component, raw unicode
        // glyphs, animated "..." loading dots tied to the global
        // DockerService.dataRefreshed signal). Replaced with the core
        // IconButton — matches every other icon-button in this shell
        // (LucideIcon-based, not raw glyphs).
        Row {
            spacing: 4 * root.uiScale

            IconButton {
                icon: "play"
                size: 22 * root.uiScale
                iconSize: 12 * root.uiScale
                visible: cd.status !== "running"
                enabled: root.pendingAction === ""
                spinning: root.pendingAction === "start"
                normalColor: Qt.rgba(Theme.color10.r, Theme.color10.g, Theme.color10.b, 0.10)
                hoverColor: Theme.color10
                fixedIconColor: Theme.color10
                tooltipText: "Start"
                onTapped: {
                    root.pendingAction = "start";
                    DockerService.containerAction("start", cd.id);
                }
            }
            IconButton {
                icon: "square"
                size: 22 * root.uiScale
                iconSize: 12 * root.uiScale
                visible: cd.status === "running"
                enabled: root.pendingAction === ""
                spinning: root.pendingAction === "stop"
                normalColor: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.10)
                hoverColor: Theme.color1
                fixedIconColor: Theme.color1
                tooltipText: "Stop"
                onTapped: {
                    root.pendingAction = "stop";
                    DockerService.containerAction("stop", cd.id);
                }
            }
            IconButton {
                icon: "refresh-cw"
                size: 22 * root.uiScale
                iconSize: 12 * root.uiScale
                visible: cd.status === "running"
                enabled: root.pendingAction === ""
                spinning: root.pendingAction === "restart"
                normalColor: Qt.rgba(Theme.color3.r, Theme.color3.g, Theme.color3.b, 0.10)
                hoverColor: Theme.color3
                fixedIconColor: Theme.color3
                tooltipText: "Restart"
                onTapped: {
                    root.pendingAction = "restart";
                    DockerService.containerAction("restart", cd.id);
                }
            }
            IconButton {
                icon: "x"
                size: 22 * root.uiScale
                iconSize: 12 * root.uiScale
                enabled: root.pendingAction === ""
                spinning: root.pendingAction === "delete"
                normalColor: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.05)
                hoverColor: Theme.color1
                fixedIconColor: Theme.color1
                tooltipText: "Delete"
                // No confirm dialog and no bubbled-up signal anymore —
                // deletes immediately on tap, same as Volumes/Images.
                onTapped: {
                    root.pendingAction = "delete";
                    DockerService.containerAction("delete", cd.id);
                }
            }
        }
    }
}
