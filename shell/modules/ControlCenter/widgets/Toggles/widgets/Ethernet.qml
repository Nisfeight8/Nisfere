import QtQuick
import qs.core
import qs.services

ControlButton {
    hasMore: true
    iconText: "ethernet-port"
    isActive: NetworkService.isEthernetConnected
    subtitle: NetworkService.ethernetName
    title: "Ethernet"
    visible: NetworkService.hasEthernet

    onClicked: NetworkService.ethernet.toggle()
    onMoreClicked: ShellState.controlCenterPageIndex = 3
}
