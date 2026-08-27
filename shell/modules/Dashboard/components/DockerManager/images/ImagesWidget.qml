import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "../components"

Rectangle {
    id: root

    property real uiScale: 1.0

    // Local pending state for the bulk prune action — cleared via the
    // explicit actionResult signal (see DockerService.qml), matched
    // specifically to "image prune" so it can't be cleared early by an
    // unrelated action (e.g. a single row's delete) or a periodic
    // stats poll landing at the wrong moment. Was previously cleared
    // via onDataRefreshed, which also fires for the Dashboard's own
    // independent 3s stats-poll timer — meaning an unrelated poll
    // response arriving WHILE this prune was still actually running in
    // the daemon would clear the spinner early, showing "done" before
    // it really was. See DockerService.qml / VolumesWidget.qml for the
    // full reasoning (same fix already applied there).
    property bool pruning: false

    Connections {
        target: DockerService
        function onActionResult(actionType, action, target, success) {
            if (actionType === "image" && action === "prune") {
                root.pruning = false;
            }
        }
    }

    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 6 * root.uiScale

        // 1. Header — same shape as ContainerListPage's
        Rectangle {
            Layout.fillWidth: true
            border.color: Theme.borderColor
            border.width: 1
            color: Theme.backgroundAlt
            height: 54 * root.uiScale
            radius: Theme.radius - 2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14 * root.uiScale
                anchors.rightMargin: 12 * root.uiScale
                spacing: 10 * root.uiScale

                LucideIcon {
                    icon: "layers"
                    size: 22 * root.uiScale
                    color: Theme.selected
                }
                Column {
                    spacing: 1 * root.uiScale

                    Text {
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 15 * root.uiScale
                        text: "Images"
                    }
                    Text {
                        color: Theme.foregroundAlt
                        font.family: Theme.fontName
                        font.pixelSize: 10 * root.uiScale
                        text: DockerService.dockerImages.length + " images"
                    }
                }
                Item {
                    Layout.fillWidth: true
                }

                NavTile {
                    icon: "sparkles"
                    label: root.pruning ? "Cleaning up..." : "Clean Up"
                    loading: root.pruning
                    uiScale: root.uiScale
                    Layout.preferredWidth: 150 * root.uiScale
                    Layout.preferredHeight: 36 * root.uiScale
                    onTapped: {
                        root.pruning = true;
                        DockerService.pruneImages();
                    }
                }
            }
        }

        // 2. Error banner — same pattern as ContainerListPage
        Rectangle {
            Layout.fillWidth: true
            border.color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.40)
            border.width: 1
            color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.12)
            height: 30 * root.uiScale
            radius: 8 * root.uiScale
            visible: DockerService.errorMessage !== "" || DockerService.lastActionError !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12 * root.uiScale
                anchors.rightMargin: 12 * root.uiScale
                spacing: 6 * root.uiScale

                LucideIcon {
                    icon: "triangle-alert"
                    size: 13 * root.uiScale
                    color: Theme.color1
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.color1
                    elide: Text.ElideRight
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    text: DockerService.errorMessage !== "" ? DockerService.errorMessage : (DockerService.lastActionErrorAction + ": " + DockerService.lastActionError)
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        CustomScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            uiScale: root.uiScale

            Column {
                spacing: 4 * root.uiScale
                width: parent.width

                Repeater {
                    model: DockerService.dockerImages

                    delegate: ImageRow {
                        required property var modelData
                        uiScale: root.uiScale
                        img: modelData
                    }
                }

                Text {
                    width: parent.width
                    visible: DockerService.dockerImages.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.foreground
                    opacity: 0.4
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    text: "No images"
                }
            }
        }
    }
}
