pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    property Connections _batteryConnections: Connections {
        function onPercentageChanged() {
            root.updateStatus();
        }
        function onReadyChanged() {
            root.updateStatus();
        }
        function onStateChanged() {
            root.updateStatus();
        }
        function onTimeToEmptyChanged() {
            root.updateStatus();
        }
        function onTimeToFullChanged() {
            root.updateStatus();
        }

        ignoreUnknownSignals: true
        target: root.displayDev
    }
    property Connections _upowerConnections: Connections {
        function onValuesChanged() {
            root.scanHardware();
        }

        ignoreUnknownSignals: true
        target: UPower.devices
    }
    property UPowerDevice displayDev: UPower.displayDevice
    property bool hasBattery: false
    property bool isCharging: false
    property int percentage: 0
    property string stateName: "Unknown"
    property string timeText: "Calculating..."

    function formatTime(seconds, prefix) {
        if (seconds <= 0)
            return "Calculating...";

        let hours = Math.floor(seconds / 3600);
        let minutes = Math.floor((seconds % 3600) / 60);

        if (hours > 0)
            return `${prefix} ${hours}h ${minutes}m`;

        return `${prefix} ${minutes} minutes`;
    }

    function scanHardware() {
        if (!UPower.devices || !UPower.devices.values)
            return;

        let found = false;
        for (let dev of UPower.devices.values) {
            if (dev.isLaptopBattery) {
                found = true;
                break;
            }
        }

        root.hasBattery = found;
        updateStatus();
    }
    function updateStatus() {
        root.percentage = Math.round(root.displayDev.percentage * 100);
        let st = root.displayDev.state;
        root.isCharging = (st === UPowerDeviceState.Charging || st === UPowerDeviceState.FullyCharged || st === UPowerDeviceState.PendingCharge);

        if (st === UPowerDeviceState.Charging)
            root.stateName = "Charging";
        else if (st === UPowerDeviceState.Discharging)
            root.stateName = "Discharging";
        else if (st === UPowerDeviceState.FullyCharged)
            root.stateName = "Fully Charged";
        else if (st === UPowerDeviceState.PendingCharge)
            root.stateName = "Plugged In (Pending)";
        else
            root.stateName = "Unknown";

        let seconds = 0;
        if (st === UPowerDeviceState.Charging) {
            seconds = root.displayDev.timeToFull;
            root.timeText = formatTime(seconds, "Full charge in");
        } else if (st === UPowerDeviceState.Discharging) {
            seconds = root.displayDev.timeToEmpty;
            root.timeText = formatTime(seconds, "Approximately remaining");
        } else if (st === UPowerDeviceState.FullyCharged) {
            root.timeText = "Using AC power";
        } else {
            root.timeText = "Calculating...";
        }
    }

    Component.onCompleted: scanHardware()
}
