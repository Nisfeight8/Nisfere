import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "../components"

Item {
    id: root
    property real uiScale: 1.0

    property var ethDevice: NetworkService.ethernet.device

    signal backRequested

    implicitHeight: mainColumn.implicitHeight

    ColumnLayout {
        id: mainColumn
        width: parent.width
        spacing: 20 * root.uiScale

        // ── Header ───────────────────────────────────────────────
        PageHeader {
            Layout.fillWidth: true
            title: "Ethernet Settings"
            uiScale: root.uiScale
            onBackRequested: root.backRequested()
        }

        // ── Info Card ──────────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true
            implicitHeight: infoLayout.implicitHeight + (30 * root.uiScale)

            ColumnLayout {
                id: infoLayout
                anchors.fill: parent
                anchors.margins: 20 * root.uiScale
                spacing: 12 * root.uiScale

                InfoRow {
                    label: "Status"
                    valueColor: (root.ethDevice && root.ethDevice.connected) ? Theme.selected : Theme.foreground
                    uiScale: root.uiScale
                    value: {
                        if (!root.ethDevice)
                            return "Not available";
                        if (!root.ethDevice.hasLink)
                            return "Cable Disconnected";
                        return root.ethDevice.connected ? "Connected" : "Disconnected";
                    }
                }

                InfoDivider {}

                InfoRow {
                    label: "Interface"
                    value: root.ethDevice ? root.ethDevice.name : "N/A"
                    uiScale: root.uiScale
                }

                InfoDivider {}

                InfoRow {
                    label: "MAC Address"
                    valueBold: false
                    value: root.ethDevice ? root.ethDevice.address : "00:00:00:00:00:00"
                    uiScale: root.uiScale
                }

                InfoDivider {
                    visible: root.ethDevice && root.ethDevice.hasLink
                }

                InfoRow {
                    visible: root.ethDevice && root.ethDevice.hasLink
                    label: "Connection Speed"
                    value: (root.ethDevice && root.ethDevice.linkSpeed > 0) ? (root.ethDevice.linkSpeed + " Mbps") : "Unknown"
                    uiScale: root.uiScale
                }
            }
        }

        // ── Actions Card ───────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true
            implicitHeight: actionsLayout.implicitHeight + (30 * root.uiScale)
            visible: root.ethDevice !== null

            ColumnLayout {
                id: actionsLayout
                anchors.fill: parent
                anchors.margins: 15 * root.uiScale
                spacing: 15 * root.uiScale

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "Automatic Connect"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 16 * root.uiScale
                        font.bold: true
                    }

                    ToggleSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: root.ethDevice ? root.ethDevice.autoconnect : false
                        uiScale: root.uiScale
                        onToggled: {
                            if (root.ethDevice)
                                root.ethDevice.autoconnect = !root.ethDevice.autoconnect;
                        }
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.topMargin: 10 * root.uiScale
                    visible: root.ethDevice && root.ethDevice.hasLink
                    label: (root.ethDevice && root.ethDevice.connected) ? "Disconnect" : "Connect"
                    baseColor: (root.ethDevice && root.ethDevice.connected) ? Theme.color1 : Theme.selected
                    uiScale: root.uiScale
                    onTapped: {
                        if (!root.ethDevice)
                            return;
                        if (root.ethDevice.connected)
                            NetworkService.ethernet.disconnect();
                        else
                            NetworkService.ethernet.connect();
                    }
                }
            }
        }
    }
}
