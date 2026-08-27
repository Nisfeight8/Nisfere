import QtQuick
import qs.core
import qs.services

ControlButton {
    hasMore: true
    iconText: Icons.getBluetoothIcon(BluetoothService.isEnabled, BluetoothService.connectedDevicesCount > 0)
    isActive: BluetoothService.isEnabled
    subtitle: BluetoothService.statusName
    title: "Bluetooth"
    visible: BluetoothService.hasBluetooth

    onClicked: BluetoothService.toggle()
    // Was `pageStack.currentIndex = 2` — same cross-file scope bug as
    // Wifi.qml; see ControlCenterContent.qml/ShellState.qml.
    onMoreClicked: ShellState.controlCenterPageIndex = 2
}
