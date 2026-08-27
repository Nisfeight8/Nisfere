import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Generalized from a container-only modal — itemKind picks which
// DockerService action to call and what label to show, so
// containers/images/volumes all share this one component instead of
// three near-identical copies. Lives in shared/ for exactly that
// reason.
Rectangle {
    id: root

    property real uiScale: 1.0

    property string itemId: ""
    property string itemName: ""
    property string itemKind: "container" // "container" | "image" | "volume"
    property bool isOpen: false

    function close() {
        isOpen = false;
    }
    function open() {
        isOpen = true;
    }

    readonly property string _kindLabel: itemKind === "image" ? "image" : itemKind === "volume" ? "volume" : "container"

    function _confirmDelete() {
        if (itemKind === "image")
            DockerService.imageAction("delete", itemId);
        else if (itemKind === "volume")
            DockerService.volumeAction("delete", itemId);
        else
            DockerService.containerAction("delete", itemId);
        root.close();
    }

    anchors.fill: parent
    border.color: Theme.borderColor
    border.width: Theme.widgetBorderWidth
    color: Theme.backgroundAlt
    radius: Theme.radius - 2
    visible: isOpen

    Rectangle {
        id: modalBox

        anchors.centerIn: parent
        border.color: Theme.borderColor
        border.width: Theme.widgetBorderWidth
        color: Theme.background
        height: 180 * root.uiScale
        radius: Theme.radius - 2
        width: 340 * root.uiScale

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16 * root.uiScale
            spacing: 12 * root.uiScale

            Text {
                Layout.fillWidth: true
                color: Theme.color1
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 14 * root.uiScale
                text: "Delete " + root._kindLabel + "?"
            }
            Text {
                Layout.fillWidth: true
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11 * root.uiScale
                text: "Are you sure you want to delete\n<b>" + root.itemName + "</b>?"
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
            }
            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * root.uiScale

                Rectangle {
                    Layout.fillWidth: true
                    border.color: Theme.borderColor
                    border.width: 1
                    color: cancelHover.hovered ? Theme.backgroundAlt : Theme.background
                    height: 36 * root.uiScale
                    radius: 8 * root.uiScale

                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 11 * root.uiScale
                        text: "Cancel"
                    }
                    HoverHandler {
                        id: cancelHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: root.close()
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    border.color: Theme.color1
                    border.width: 1
                    color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, deleteHover.hovered ? 0.28 : 0.15)
                    height: 36 * root.uiScale
                    radius: 8 * root.uiScale

                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        color: Theme.color1
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 11 * root.uiScale
                        text: "Delete"
                    }
                    HoverHandler {
                        id: deleteHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: root._confirmDelete()
                    }
                }
            }
        }
    }
}