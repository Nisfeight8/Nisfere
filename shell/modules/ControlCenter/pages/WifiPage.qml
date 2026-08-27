import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Networking
import qs.core
import qs.services
import "../components"

Item {
    id: root

    property real uiScale: 1.0
    implicitHeight: mainColumn.implicitHeight

    property string activeSsidPrompt: ""
    property var wifiDevice: NetworkService.wifi.device

    signal backRequested

    ColumnLayout {
        id: mainColumn
        width: parent.width
        spacing: 16 * root.uiScale

        // ── Header ───────────────────────────────────────────────
        PageHeader {
            Layout.fillWidth: true
            title: "Wi-Fi"
            uiScale: root.uiScale
            onBackRequested: root.backRequested()

            ToggleSwitch {
                checked: NetworkService.wifiEnabled
                uiScale: root.uiScale
                onToggled: NetworkService.wifi.toggle()
            }
        }
        SectionLabel {
            Layout.bottomMargin: 6 * root.uiScale
            text: "Available Networks"
            uiScale: root.uiScale
        }
        // ── Network List (WiFi ON) ────────────────────────────────
        CustomScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(networksColumn.implicitHeight, 400 * root.uiScale)
            uiScale: root.uiScale
            visible: NetworkService.wifiEnabled && root.wifiDevice !== null

            ColumnLayout {
                id: networksColumn
                width: scrollView.width
                spacing: 6 * root.uiScale

                Repeater {
                    model: root.wifiDevice ? NetworkService.wifi.sortedNetworks : null

                    delegate: GlassCard {
                        id: netCard
                        Layout.fillWidth: true

                        readonly property bool expanded: root.activeSsidPrompt === modelData.name
                        property string localError: ""
                        readonly property bool hasError: localError !== ""

                        implicitHeight: expanded ? (hasError ? 138 * root.uiScale : 116 * root.uiScale) : 70 * root.uiScale
                        clip: true

                        Behavior on implicitHeight {
                            Anim {
                                type: Anim.FastToggle
                            }
                        }

                        Connections {
                            target: NetworkService.wifi
                            function onErrorOccurred(ssid, errorMessage) {
                                if (modelData.name === ssid) {
                                    netCard.localError = errorMessage;
                                    errorTimer.restart();
                                }
                            }
                        }

                        Timer {
                            id: errorTimer
                            interval: 10000
                            repeat: false
                            onTriggered: netCard.localError = ""
                        }

                        // Was missing entirely — the password prompt
                        // (activeSsidPrompt) never closed itself after
                        // a SUCCESSFUL connection, only on an explicit
                        // Cancel tap. Collapses back to the compact
                        // row automatically once this network actually
                        // becomes connected while its prompt was open.
                        Connections {
                            target: modelData
                            function onConnectedChanged() {
                                if (modelData.connected && root.activeSsidPrompt === modelData.name) {
                                    root.activeSsidPrompt = "";
                                    passwordInput.text = "";
                                    netCard.localError = "";
                                }
                            }
                        }

                        // ── Info row ────────────────────────────────
                        RowLayout {
                            id: infoRow
                            anchors {
                                top: parent.top
                                topMargin: 12 * root.uiScale
                                left: parent.left
                                leftMargin: 12 * root.uiScale
                                right: parent.right
                                rightMargin: 12 * root.uiScale
                            }
                            height: 46 * root.uiScale
                            spacing: 10 * root.uiScale

                            LucideIcon {
                                Layout.alignment: Qt.AlignVCenter
                                color: modelData.connected ? Theme.selected : Theme.foreground
                                size: 16 * root.uiScale
                                opacity: modelData.connected ? 1.0 : 0.75
                                icon: Icons.getWifiItemIcon(modelData.signalStrength)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2 * root.uiScale

                                Text {
                                    Layout.fillWidth: true
                                    color: Theme.foreground
                                    font.pixelSize: 13 * root.uiScale
                                    font.bold: modelData.connected
                                    text: modelData.name
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    color: modelData.connected ? Theme.selected : (netCard.hasError ? Theme.color1 : Theme.foreground)
                                    font.pixelSize: 11 * root.uiScale
                                    opacity: (modelData.connected || netCard.hasError) ? 1.0 : 0.5
                                    // modelData.stateChanging (native, see
                                    // Quickshell.Networking.Network) is
                                    // true while connecting/
                                    // disconnecting — surfaced here so
                                    // the status text itself says so,
                                    // not just the button spinner.
                                    text: {
                                        if (netCard.hasError)
                                            return "Connection Failed";
                                        if (modelData.stateChanging)
                                            return modelData.connected ? "Disconnecting..." : "Connecting...";
                                        if (modelData.connected)
                                            return "Connected";
                                        return "Saved";
                                    }
                                    visible: modelData.connected || modelData.known || netCard.hasError || modelData.stateChanging
                                }
                            }

                            LucideIcon {
                                Layout.alignment: Qt.AlignVCenter
                                color: Theme.foreground
                                size: 14 * root.uiScale
                                opacity: 0.3
                                icon: "lock"
                                visible: modelData.security !== WifiSecurityType.Open && !modelData.connected && !modelData.known
                            }

                            IconButton {
                                id: actionBtn
                                size: 32 * root.uiScale
                                iconSize: 16 * root.uiScale
                                Layout.alignment: Qt.AlignVCenter
                                hoverSolid: true
                                alwaysBorder: true
                                borderColor: (modelData.connected || netCard.expanded) ? Theme.color1 : Theme.selected
                                contrastColor: Theme.background
                                icon: Icons.getWifiActionIcon(netCard.expanded, modelData.connected)
                                hoverColor: (modelData.connected || netCard.expanded) ? Theme.color1 : Theme.selected
                                tooltipText: modelData.connected ? "Disconnect" : netCard.expanded ? "Cancel" : "Connect"
                                // Native stateChanging drives real
                                // spin/disable feedback — no custom
                                // pending-tracking needed, unlike
                                // Bluetooth (which had no equivalent
                                // native flag for a plain reconnect).
                                spinning: modelData.stateChanging
                                enabled: !modelData.stateChanging
                                onTapped: {
                                    if (netCard.expanded) {
                                        root.activeSsidPrompt = "";
                                        passwordInput.text = "";
                                        netCard.localError = "";
                                    } else if (modelData.connected) {
                                        NetworkService.wifi.disconnect();
                                    } else if (modelData.known || modelData.security === WifiSecurityType.Open) {
                                        NetworkService.wifi.connectTo(modelData.name);
                                    } else {
                                        root.activeSsidPrompt = modelData.name;
                                        Qt.callLater(() => passwordInput.forceActiveFocus());
                                    }
                                }
                            }
                        }

                        // ── Password row ───────────────────────────
                        RowLayout {
                            id: passwordRow
                            anchors {
                                top: infoRow.bottom
                                topMargin: 8 * root.uiScale
                                left: parent.left
                                leftMargin: 12 * root.uiScale
                                right: parent.right
                                rightMargin: 12 * root.uiScale
                            }
                            height: 38 * root.uiScale
                            spacing: 8 * root.uiScale
                            opacity: netCard.expanded ? 1.0 : 0.0
                            Behavior on opacity {
                                Anim {
                                    type: Anim.FastEffects
                                }
                            }

                            TextField {
                                id: passwordInput
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 34 * root.uiScale
                                color: Theme.foreground
                                echoMode: TextInput.Password
                                placeholderText: "Password…"
                                placeholderTextColor: netCard.hasError ? Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.6) : Theme.selected
                                font.pixelSize: 13 * root.uiScale
                                leftPadding: 10 * root.uiScale
                                rightPadding: 10 * root.uiScale
                                enabled: !modelData.stateChanging

                                background: Rectangle {
                                    border.color: netCard.hasError ? Theme.color1 : Theme.selected
                                    border.width: Theme.widgetBorderWidth
                                    color: Theme.backgroundAlt
                                    radius: Theme.radius
                                    Behavior on border.color {
                                        AnimColor {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }

                                Keys.onReturnPressed: {
                                    netCard.localError = "";
                                    NetworkService.wifi.connectTo(modelData.name, text);
                                }
                            }

                            IconButton {
                                size: 32 * root.uiScale
                                iconSize: 16 * root.uiScale
                                icon: "check"
                                hoverSolid: true
                                alwaysBorder: true
                                borderColor: Theme.selected
                                contrastColor: Theme.background
                                hoverColor: Theme.selected
                                tooltipText: "Connect"
                                spinning: modelData.stateChanging
                                enabled: !modelData.stateChanging
                                onTapped: {
                                    netCard.localError = "";
                                    NetworkService.wifi.connectTo(modelData.name, passwordInput.text);
                                }
                            }
                        }

                        // ── Error text ──────────────────────────────
                        Text {
                            anchors {
                                top: passwordRow.bottom
                                topMargin: 4 * root.uiScale
                                left: parent.left
                                leftMargin: 16 * root.uiScale
                                right: parent.right
                                rightMargin: 12 * root.uiScale
                            }
                            text: netCard.localError
                            color: Theme.color1
                            font.pixelSize: 11 * root.uiScale
                            opacity: netCard.hasError ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity {
                                Anim {
                                    type: Anim.FastEffects
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── WiFi Off State ─────────────────────────────────────────
        DisabledStateCard {
            Layout.fillWidth: true
            implicitHeight: 150 * root.uiScale
            visible: !NetworkService.wifiEnabled
            icon: "wifi-off"
            message: "Wi-Fi is turned off"
        }
    }
}
