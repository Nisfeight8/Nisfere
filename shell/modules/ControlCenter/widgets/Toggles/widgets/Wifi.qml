import QtQuick

import qs.core
import qs.services

ControlButton {
    hasMore: true
    // Was `isWifiConnecte` — typo, non-existent property (undefined),
    // matches `isWifiConnected` used correctly everywhere else (e.g.
    // InternalTrayWidget.qml).
    iconText: Icons.getWifiIcon(NetworkService.wifiEnabled, NetworkService.isWifiConnected, NetworkService.wifi.netStrength)
    isActive: NetworkService.isWifiConnected
    subtitle: NetworkService.wifiName
    title: "Wi-Fi"
    visible: NetworkService.hasWifi

    onClicked: NetworkService.wifi.toggle()

    onMoreClicked: ShellState.controlCenterPageIndex = 1
}
