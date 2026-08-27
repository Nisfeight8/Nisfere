import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Rectangle {
    id: root

    property real uiScale: 1.0
    property string currentStatus: details ? details.status : ""
    property var details: DockerService.activeContainerDetails

    // Same spinning experiment as ContainerRow.qml — see its comment
    // for the full reasoning/caveat.
    property string pendingAction: ""

    Connections {
        target: DockerService
        // Matched via actionResult (see DockerService.qml/ChatKit
        // reasoning already applied to ContainerRow/ProjectSection) —
        // NOT the old dataRefreshed signal, which also fires from the
        // Dashboard's own independent 3s stats-poll timer and could
        // clear this prematurely while the real action was still
        // running. root.details can be null here (back button and
        // Component.onDestruction both clear it), hence the guard.
        function onActionResult(actionType, action, target, success) {
            if (actionType === "container" && root.details && target === root.details.id) {
                root.pendingAction = "";
            }
        }
    }

    color: Theme.background

    Component.onDestruction: {
        DockerService.isViewingDetails = false;
        DockerService.stopStream();
        DockerService.liveLogs = "";
    }
    onDetailsChanged: {
        if (!details)
            return;

        if (details.status === "running") {
            DockerService.startStream(details.id, details.logs);
        } else {
            DockerService.stopStream();
            if (DockerService.liveLogs === "") {
                DockerService.liveLogs = details.logs || "No logs available";
                DockerService.liveCpu = "0%";
                DockerService.liveRam = "0B";
            }
        }
    }

    Text {
        anchors.centerIn: parent
        color: Theme.foregroundAlt
        font.family: Theme.fontName
        font.pixelSize: 14 * root.uiScale
        text: "Loading..."
        visible: !root.details
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6 * root.uiScale
        spacing: 12 * root.uiScale
        visible: !!root.details

        RowLayout {
            Layout.fillWidth: true
            spacing: 10 * root.uiScale

            // Back button — was root.StackView.view.pop(StackView.
            // Immediate), which relied on being inside a StackView.
            // ContainersWidget now swaps list/details via AnimLoader
            // driven directly by DockerService.isViewingDetails, so
            // going back is just clearing that flag — no view/stack
            // reference needed at all. Also: raw Nerd Font glyph ->
            // LucideIcon, MouseArea -> TapHandler+HoverHandler.
            Rectangle {
                border.color: Theme.borderColor
                border.width: 1
                color: backHover.hovered ? Theme.backgroundAlt : "transparent"
                height: 32 * root.uiScale
                radius: Theme.radius
                width: 32 * root.uiScale

                LucideIcon {
                    anchors.centerIn: parent
                    icon: "arrow-left"
                    size: 16 * root.uiScale
                    color: Theme.foreground
                }
                HoverHandler {
                    id: backHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: {
                        DockerService.isViewingDetails = false;
                        DockerService.activeContainerDetails = null;
                    }
                }
            }

            // Container info
            Column {
                Layout.fillWidth: true
                spacing: 2 * root.uiScale

                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.pixelSize: 18 * root.uiScale
                    text: root.details ? root.details.name : ""
                }
                Text {
                    color: Theme.foregroundAlt
                    elide: Text.ElideRight
                    font.pixelSize: 11 * root.uiScale
                    text: "Image: " + (root.details ? root.details.image : "")
                    width: parent.width
                }
            }

            // Was 3 ActionButton instances — same IconButton
            // replacement as ContainerRow/ProjectSection.
            Row {
                spacing: 6 * root.uiScale

                IconButton {
                    icon: "play"
                    size: 32 * root.uiScale
                    iconSize: 15 * root.uiScale
                    visible: root.details && root.details.status !== "running"
                    enabled: root.pendingAction === ""
                    spinning: root.pendingAction === "start"
                    normalColor: Qt.rgba(Theme.color10.r, Theme.color10.g, Theme.color10.b, 0.10)
                    hoverColor: Theme.color10
                    fixedIconColor: Theme.color10
                    tooltipText: "Start"
                    onTapped: {
                        root.pendingAction = "start";
                        DockerService.containerAction("start", root.details.id);
                    }
                }
                IconButton {
                    icon: "square"
                    size: 32 * root.uiScale
                    iconSize: 15 * root.uiScale
                    visible: root.details && root.details.status === "running"
                    enabled: root.pendingAction === ""
                    spinning: root.pendingAction === "stop"
                    normalColor: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.10)
                    hoverColor: Theme.color1
                    fixedIconColor: Theme.color1
                    tooltipText: "Stop"
                    onTapped: {
                        root.pendingAction = "stop";
                        DockerService.containerAction("stop", root.details.id);
                    }
                }
                IconButton {
                    icon: "refresh-cw"
                    size: 32 * root.uiScale
                    iconSize: 15 * root.uiScale
                    visible: root.details && root.details.status === "running"
                    enabled: root.pendingAction === ""
                    spinning: root.pendingAction === "restart"
                    normalColor: Qt.rgba(Theme.color3.r, Theme.color3.g, Theme.color3.b, 0.10)
                    hoverColor: Theme.color3
                    fixedIconColor: Theme.color3
                    tooltipText: "Restart"
                    onTapped: {
                        root.pendingAction = "restart";
                        DockerService.containerAction("restart", root.details.id);
                    }
                }
            }
        }

        // ── STATUS BAR ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            border.color: Theme.borderColor
            border.width: 1
            color: Theme.backgroundAlt
            height: 40 * root.uiScale
            radius: 6 * root.uiScale

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12 * root.uiScale
                spacing: 6 * root.uiScale

                Text {
                    color: Theme.color4
                    font.pixelSize: 12 * root.uiScale
                    text: "Status: " + (root.details ? root.details.status : "")
                }
                Item {
                    Layout.fillWidth: true
                }
                LucideIcon {
                    icon: "cpu"
                    size: 13 * root.uiScale
                    color: Theme.color10
                }
                Text {
                    color: Theme.color10
                    font.bold: true
                    font.pixelSize: 12 * root.uiScale
                    text: "CPU: " + DockerService.liveCpu
                }
                LucideIcon {
                    icon: "memory-stick"
                    size: 13 * root.uiScale
                    color: Theme.color11
                }
                Text {
                    color: Theme.color11
                    font.bold: true
                    font.pixelSize: 12 * root.uiScale
                    text: "RAM: " + DockerService.liveRam
                }
            }
        }
        Text {
            color: Theme.foreground
            font.bold: true
            font.family: Theme.fontName
            font.pixelSize: 16 * root.uiScale
            text: "Recent Logs"
        }
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            border.color: Theme.borderColor
            border.width: 1
            color: Theme.backgroundAlt
            radius: Theme.radius

            CustomScrollView {
                id: logScroll
                uiScale: root.uiScale

                anchors.fill: parent
                anchors.margins: 10 * root.uiScale
                clip: true

                TextEdit {
                    id: logText

                    color: Theme.color2
                    font.family: "Monospace"
                    font.pixelSize: 11 * root.uiScale
                    readOnly: true
                    selectByMouse: true
                    text: DockerService.liveLogs
                    width: parent.width
                    wrapMode: Text.WrapAnywhere

                    onTextChanged: {
                        logText.cursorPosition = logText.text.length;
                        if (logScroll.ScrollBar.vertical.size < 1.0) {
                            logScroll.ScrollBar.vertical.position = 1.0 - logScroll.ScrollBar.vertical.size;
                        }
                    }
                }
            }
        }
    }
}
