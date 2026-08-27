import QtQuick
import QtQuick.Layouts
import qs.core

Column {
    id: root

    property real uiScale: 1.0
    property var containers: []

    spacing: 2 * uiScale
    visible: containers.length > 0
    width: parent.width

    Rectangle {
        border.color: Qt.rgba(Theme.color5.r, Theme.color5.g, Theme.color5.b, 0.28)
        border.width: 1
        color: Qt.rgba(Theme.color5.r, Theme.color5.g, Theme.color5.b, 0.08)
        height: 36 * root.uiScale
        radius: Theme.radius - 4
        width: parent.width

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12 * root.uiScale
            anchors.rightMargin: 12 * root.uiScale
            spacing: 6 * root.uiScale

            // Was "⬡  Standalone" as one raw-glyph-plus-text string —
            // split into a proper LucideIcon + Text, matching how
            // every other icon in this shell is rendered.
            LucideIcon {
                icon: "hexagon"
                size: 13 * root.uiScale
                color: Theme.color5
            }
            Text {
                color: Theme.color5
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 12 * root.uiScale
                text: "Standalone"
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                property int cnt: root.containers.length

                color: Theme.foregroundAlt
                font.family: Theme.fontName
                font.pixelSize: 10 * root.uiScale
                text: cnt + " container" + (cnt !== 1 ? "s" : "")
            }
        }
    }

    Repeater {
        model: root.containers

        delegate: ContainerRow {
            required property var modelData
            uiScale: root.uiScale
            cd: modelData
            isStandalone: true
        }
    }
}
