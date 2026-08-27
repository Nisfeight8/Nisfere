import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Column {
    id: root

    property real uiScale: 1.0
    property bool isExpanded: true
    // Was `property var proj: null` — projRunning below reads
    // proj.containers immediately at binding-evaluation time, which
    // risked a transient null read. required guarantees a real value
    // at creation, same convention used throughout this shell.
    required property var proj

    readonly property int projRunning: (proj.containers ?? []).filter(c => c.status === "running").length

    signal toggleRequested

    // Same spinning experiment as ContainerRow.qml — see its comment
    // for the full reasoning/caveat.
    property string pendingAction: ""

    Connections {
        target: DockerService
        // Compose actions send the WHOLE project object as their
        // "target" (working_dir + config_files — see
        // DockerService.composeAction), not a plain id string like
        // container/image/volume actions do. The daemon echoes back
        // just {working_dir} in action_result for this reason (see
        // docker_manager.py) — working_dir is the stable correlation
        // key here, matched against THIS project's own working_dir so
        // a different project's compose action can never clear this
        // one's spinner.
        function onActionResult(actionType, action, target, success) {
            if (actionType === "compose" && target && target.working_dir === root.proj.working_dir) {
                root.pendingAction = "";
            }
        }
    }

    spacing: 2 * root.uiScale
    width: parent.width

    // Project header
    Rectangle {
        border.color: root.isExpanded ? Qt.rgba(Theme.color4.r, Theme.color4.g, Theme.color4.b, 0.50) : Theme.borderColor
        border.width: 1
        color: Theme.backgroundAlt
        height: 58 * root.uiScale
        radius: Theme.radius
        width: parent.width

        Behavior on border.color {
            ColorAnimation {
                duration: 180
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12 * root.uiScale
            anchors.rightMargin: 14 * root.uiScale
            spacing: 8 * root.uiScale

            // Toggle Icon — was raw "▼"/"▶" text glyphs, replaced
            // with LucideIcon like every other icon in this shell.
            // MouseArea -> HoverHandler+TapHandler.
            Rectangle {
                id: toggleBtn
                color: toggleHover.hovered ? Qt.rgba(Theme.color4.r, Theme.color4.g, Theme.color4.b, 0.18) : "transparent"
                height: 20 * root.uiScale
                radius: 4 * root.uiScale
                width: 20 * root.uiScale

                LucideIcon {
                    anchors.centerIn: parent
                    icon: root.isExpanded ? "chevron-down" : "chevron-right"
                    size: 12 * root.uiScale
                    color: Theme.color4
                }
                HoverHandler {
                    id: toggleHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: root.toggleRequested()
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 2 * root.uiScale

                Text {
                    color: Theme.color4
                    font.bold: true
                    font.pixelSize: 13 * root.uiScale
                    text: root.proj.name
                }
                Text {
                    color: Theme.foregroundAlt
                    elide: Text.ElideMiddle
                    font.pixelSize: 10 * root.uiScale
                    text: root.proj.working_dir || "—"
                    width: 170 * root.uiScale
                }
            }
            Text {
                color: root.projRunning === root.proj.containers.length ? Theme.color10 : root.projRunning === 0 ? Theme.foregroundAlt : Theme.color3
                font.bold: true
                font.pixelSize: 11 * root.uiScale
                text: root.projRunning + "/" + root.proj.containers.length
            }

            // Was 4 ActionButton instances — same IconButton
            // replacement as ContainerRow.qml, same reasoning (no raw
            // glyphs, no animated loading dots, no spin/rotation).
            // composeAction takes the FULL project object (not just
            // working_dir) — the daemon's docker_action_async reads
            // both working_dir AND config_files off it.
            Row {
                spacing: 4 * root.uiScale

                IconButton {
                    icon: "play"
                    size: 22 * root.uiScale
                    iconSize: 12 * root.uiScale
                    visible: root.projRunning === 0
                    enabled: root.pendingAction === ""
                    spinning: root.pendingAction === "up"
                    normalColor: Qt.rgba(Theme.color10.r, Theme.color10.g, Theme.color10.b, 0.10)
                    hoverColor: Theme.color10
                    fixedIconColor: Theme.color10
                    tooltipText: "Start project"
                    onTapped: {
                        root.pendingAction = "up";
                        DockerService.composeAction("up", root.proj);
                    }
                }
                IconButton {
                    icon: "square"
                    size: 22 * root.uiScale
                    iconSize: 12 * root.uiScale
                    visible: root.projRunning > 0
                    enabled: root.pendingAction === ""
                    spinning: root.pendingAction === "stop"
                    normalColor: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.10)
                    hoverColor: Theme.color1
                    fixedIconColor: Theme.color1
                    tooltipText: "Stop project"
                    onTapped: {
                        root.pendingAction = "stop";
                        DockerService.composeAction("stop", root.proj);
                    }
                }
                IconButton {
                    icon: "refresh-cw"
                    size: 22 * root.uiScale
                    iconSize: 12 * root.uiScale
                    visible: root.projRunning > 0
                    enabled: root.pendingAction === ""
                    spinning: root.pendingAction === "restart"
                    normalColor: Qt.rgba(Theme.color3.r, Theme.color3.g, Theme.color3.b, 0.10)
                    hoverColor: Theme.color3
                    fixedIconColor: Theme.color3
                    tooltipText: "Restart project"
                    onTapped: {
                        root.pendingAction = "restart";
                        DockerService.composeAction("restart", root.proj);
                    }
                }
                IconButton {
                    icon: "x"
                    size: 22 * root.uiScale
                    iconSize: 12 * root.uiScale
                    enabled: root.pendingAction === ""
                    spinning: root.pendingAction === "down"
                    normalColor: Qt.rgba(Theme.color9.r, Theme.color9.g, Theme.color9.b, 0.10)
                    hoverColor: Theme.color9
                    fixedIconColor: Theme.color9
                    tooltipText: "Tear down project"
                    onTapped: {
                        root.pendingAction = "down";
                        DockerService.composeAction("down", root.proj);
                    }
                }
            }
        }
    }

    // Containers List
    Column {
        bottomPadding: 4 * root.uiScale
        spacing: 2 * root.uiScale
        topPadding: 2 * root.uiScale
        visible: root.isExpanded
        width: parent.width

        Repeater {
            model: root.proj.containers

            delegate: ContainerRow {
                required property var modelData
                uiScale: root.uiScale
                cd: modelData
                width: parent.width - 10 * root.uiScale
                x: 10 * root.uiScale
                isStandalone: false
            }
        }
    }
}
