import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Rectangle {
    id: root

    property real uiScale: 1.0
    required property var img // {id, name, tag, size}

    // True while THIS row's own delete is in flight. Cleared via the
    // explicit actionResult signal (see DockerService.qml), matched
    // specifically to an "image delete" whose target is THIS image's
    // id — so a delete on a DIFFERENT row, or the bulk "Clean Up"
    // prune action, can never affect this row's spinner.
    property bool deleting: false

    Connections {
        target: DockerService
        function onActionResult(actionType, action, target, success) {
            if (actionType === "image" && action === "delete" && target === root.img.id) {
                root.deleting = false;
            }
        }
    }

    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.40)
    border.width: 1
    color: Theme.backgroundAlt
    height: 42 * root.uiScale
    radius: Theme.radius
    width: parent.width

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10 * root.uiScale
        anchors.rightMargin: 10 * root.uiScale
        spacing: 8 * root.uiScale

        LucideIcon {
            icon: "layers"
            size: 14 * root.uiScale
            color: Theme.color6
        }

        Column {
            Layout.fillWidth: true
            spacing: 1 * root.uiScale

            Text {
                width: parent.width
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 12 * root.uiScale
                text: root.img.name + ":" + root.img.tag
            }
            Text {
                color: Theme.foregroundAlt
                font.family: Theme.fontName
                font.pixelSize: 10 * root.uiScale
                text: root.img.size
            }
        }

        IconButton {
            icon: "x"
            size: 22 * root.uiScale
            iconSize: 12 * root.uiScale
            normalColor: Qt.rgba(Theme.color9.r, Theme.color9.g, Theme.color9.b, 0.10)
            hoverColor: Theme.color9
            fixedIconColor: Theme.color9
            tooltipText: "Delete"
            spinning: root.deleting
            enabled: !root.deleting
            // No confirm dialog — deletes immediately on tap, spinner
            // on this button covers the whole round trip (see the
            // Connections block above for when it clears).
            onTapped: {
                root.deleting = true;
                DockerService.imageAction("delete", root.img.id);
            }
        }
    }
}
