import QtQuick
import QtQuick.Layouts
import qs.core

// Generic "this feature is off" empty state — for Wi-Fi/Bluetooth/
// Ethernet pages when the underlying hardware/service is disabled.
// Wrapped in a plain Item + anchors.centerIn (not Layout.alignment
// inside a fillWidth ColumnLayout) — the reliable centering pattern,
// safe regardless of what kind of container this is placed in.
//
// Usage:
//   DisabledStateCard {
//       anchors.fill: parent
//       icon: "bluetooth-off"
//       message: "Bluetooth is turned off"
//       actionLabel: "Turn on"
//       onActionClicked: BluetoothService.toggle()
//   }
Item {
    id: root

    property string icon: "power-off"
    property string message: "This feature is turned off"
    property string actionLabel: ""   // "" = no action button shown
    signal actionClicked

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        LucideIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: root.icon
            size: 40
            color: Theme.foreground
            opacity: 0.35
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.message
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 13
            opacity: 0.5
            horizontalAlignment: Text.AlignHCenter
        }

        NavTile {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 140
            visible: root.actionLabel !== ""
            icon: "power"
            label: root.actionLabel
            onTapped: root.actionClicked()
        }
    }
}
