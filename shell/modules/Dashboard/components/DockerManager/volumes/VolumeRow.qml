import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Rectangle {
    id: root

    property real uiScale: 1.0
    required property var vol // {name, driver, mountpoint}

    // True while THIS row's own delete is in flight. Cleared via the
    // explicit actionResult signal (see DockerService.qml), matched
    // specifically to a "volume delete" whose target is THIS volume's
    // name — so a delete on a DIFFERENT row, or the bulk "Clean Up"
    // prune action, can never affect this row's spinner.
    property bool deleting: false

    Connections {
        target: DockerService
        function onActionResult(actionType, action, target, success) {
            if (actionType === "volume" && action === "delete" && target === root.vol.name) {
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
            icon: "database"
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
                text: root.vol.name
            }
            Text {
                width: parent.width
                color: Theme.foregroundAlt
                elide: Text.ElideMiddle
                font.family: Theme.fontName
                font.pixelSize: 10 * root.uiScale
                text: root.vol.driver + " · " + (root.vol.mountpoint || "—")
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
                DockerService.volumeAction("delete", root.vol.name);
            }
        }
    }
}
