import QtQuick
import Quickshell
import qs.core
import qs.services

BarWidget {
    id: root
    useGradient: true

    HoverHandler {
        parent: root
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        parent: root
        onTapped: ShellState.toggleControlCenter(QsWindow.window?.screen?.name ?? "")
    }
    spacing: 4

    // --- Network Icon ---
    Loader {
        active: NetworkService.hasEthernet || NetworkService.hasWifi
        asynchronous: false
        sourceComponent: Component {
            TrayIcon {
                iconSize: root.iconSize
                fontSize: root.fontSize
                iconName: {
                    if (NetworkService.isEthernetConnected)
                        return "network";
                    if (NetworkService.hasWifi)
                        return Icons.getWifiIcon(NetworkService.wifiEnabled, NetworkService.isWifiConnected, NetworkService.wifi.netStrength);
                    return "wifi-off";
                }

                tooltipText: {
                    if (NetworkService.isEthernetConnected) {
                        return "Network: Ethernet\nStatus: Connected";
                    } else if (NetworkService.hasWifi) {
                        if (NetworkService.isWifiConnected) {
                            return `Wi-Fi: ${NetworkService.wifiName}\nSignal: ${Math.round(NetworkService.wifi.netStrength * 100)}%`;
                        } else if (NetworkService.wifiEnabled) {
                            return "Wi-Fi: Searching...";
                        } else {
                            return "Wi-Fi: Disabled";
                        }
                    }
                    return "Network: Unavailable";
                }
            }
        }
    }

    // --- Bluetooth Icon ---
    Loader {
        active: BluetoothService.hasBluetooth
        asynchronous: false
        sourceComponent: Component {
            TrayIcon {
                iconSize: root.iconSize
                fontSize: root.fontSize
                iconName: Icons.getBluetoothIcon(BluetoothService.isEnabled, BluetoothService.connectedDevicesCount > 0)
                infoText: BluetoothService.connectedDevicesCount > 0 ? BluetoothService.connectedDevicesCount.toString() : ""
                tooltipText: {
                    if (!BluetoothService.isEnabled) {
                        return "Bluetooth: Disabled";
                    } else if (BluetoothService.connectedDevicesCount === 0) {
                        return BluetoothService.isScanning ? "Bluetooth: Searching..." : "Bluetooth: On";
                    } else {
                        return `Bluetooth: ${BluetoothService.statusName}`;
                    }
                }
            }
        }
    }

    // --- Brightness Icon ---
    Loader {
        active: BrightnessService.isAvailable
        asynchronous: false
        sourceComponent: Component {
            TrayIcon {
                iconSize: root.iconSize
                fontSize: root.fontSize
                iconName: "sun"
                tooltipText: `Brightness: ${Math.round(BrightnessService.percentage * 100)}%`
            }
        }
    }

    // --- Volume Icon (Always active) ---
    TrayIcon {
        iconSize: root.iconSize
        fontSize: root.fontSize
        iconName: Icons.getVolumeIcon(AudioService.volume, AudioService.muted)
        tooltipText: {
            if (AudioService.muted) {
                return "Volume: Muted";
            } else {
                return `Volume: ${Math.round(AudioService.volume * 100)}%`;
            }
        }
    }
}
