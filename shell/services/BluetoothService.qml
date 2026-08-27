pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    // Was an imperative updateStatus() function, manually triggered by
    // a handful of Connections blocks (adapter enabled/discovering/
    // state, Bluetooth.defaultAdapter changing, Bluetooth.devices'
    // onValuesChanged). That last one only fires when the DEVICE LIST
    // itself changes (a device appearing/disappearing) — not when an
    // EXISTING device's own .connected property changes, which is
    // exactly what clicking Connect/Disconnect does. So updateStatus()
    // never re-ran after connecting, and statusName/
    // connectedDevicesCount stayed stale — while BluetoothPage.qml's
    // per-row `model.connected` bindings correctly updated, since
    // those are direct property bindings, not something gated behind
    // the list's own change signal.
    //
    // Rewritten as plain readonly property bindings — QML's own
    // dependency tracking registers EVERY property actually read
    // during a binding's evaluation, including `dev.connected` for
    // each device inside the filter() below, so this now reacts
    // correctly to any individual device's connected state changing,
    // with no signal-wiring to get wrong.
    readonly property var _adapter: Bluetooth.defaultAdapter
    readonly property bool hasBluetooth: _adapter !== null
    readonly property bool isEnabled: hasBluetooth && _adapter.enabled
    readonly property bool isScanning: hasBluetooth && _adapter.discovering

    readonly property var _connectedDevices: {
        if (!Bluetooth.devices || !Bluetooth.devices.values)
            return [];
        return Bluetooth.devices.values.filter(d => d.connected);
    }
    readonly property int connectedDevicesCount: _connectedDevices.length
    readonly property string connectedDeviceName: connectedDevicesCount > 0 ? (_connectedDevices[0].name !== "" ? _connectedDevices[0].name : _connectedDevices[0].deviceName) : ""

    readonly property string statusName: {
        if (!hasBluetooth)
            return "There is no hardware";
        if (_adapter.state === BluetoothAdapterState.Disabled)
            return "Closed";
        if (_adapter.state === BluetoothAdapterState.Blocked)
            return "Blocked";
        if (_adapter.state === BluetoothAdapterState.Enabling)
            return "Enable...";
        if (_adapter.state === BluetoothAdapterState.Disabling)
            return "Disable...";
        if (connectedDevicesCount === 0)
            return isScanning ? "Searching..." : "Disconnected";
        if (connectedDevicesCount === 1)
            return connectedDeviceName;
        return connectedDevicesCount + " Devices";
    }

    function toggle() {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    }
    function toggleScan() {
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
            Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering;
    }
}
