
import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services
import "widgets"

GridLayout {
    id: grid
    property real uiScale: 1.0
    Layout.fillWidth: true
    columnSpacing: 10 * uiScale
    columns: 2
    rowSpacing: 10 * uiScale

    property var activeWidgets: []

    Component {
        id: ethernetComp
        Ethernet {
            uiScale: grid.uiScale
        }
    }
    Component {
        id: wifiComp
        Wifi {
            uiScale: grid.uiScale
        }
    }
    Component {
        id: bluetoothComp
        Bluetooth {
            uiScale: grid.uiScale
        }
    }
    Component {
        id: themeToggleComp
        ThemeToggle {
            uiScale: grid.uiScale
        }
    }
    Component {
        id: keyboardToggleComp
        KeyboardToggle {
            uiScale: grid.uiScale
        }
    }
    Component {
        id: dndComp
        Dnd {
            uiScale: grid.uiScale
        }
    }
    Component {
        id: nightLightComp
        NightLight {
            uiScale: grid.uiScale
        }
    }
    Component {
        id: powerProfileComp
        PowerProfile {
            uiScale: grid.uiScale
        }
    }

    function updateWidgets() {
        var items = [
            {
                comp: ethernetComp,
                active: NetworkService.hasEthernet
            },
            {
                comp: wifiComp,
                active: NetworkService.hasWifi
            },
            {
                comp: bluetoothComp,
                active: BluetoothService.hasBluetooth
            },
            {
                comp: themeToggleComp,
                active: true
            },
            {
                comp: keyboardToggleComp,
                active: KeyboardService.availableLayouts.length > 1
            },
            {
                comp: dndComp,
                active: true
            },
            {
                comp: nightLightComp,
                active: true
            },
            {
                comp: powerProfileComp,
                active: true
            }
        ];

        var filtered = items.filter(function (item) {
            return item.active;
        });

        if (activeWidgets.length !== filtered.length) {
            activeWidgets = filtered;
        }
    }

    Connections {
        target: NetworkService
        function onHasEthernetChanged() {
            updateWidgets();
        }
        function onHasWifiChanged() {
            updateWidgets();
        }
    }
    Connections {
        target: BluetoothService
        function onHasBluetoothChanged() {
            updateWidgets();
        }
    }
    Connections {
        target: KeyboardService
        function onAvailableLayoutsChanged() {
            updateWidgets();
        }
    }
    Component.onCompleted: updateWidgets()

    Repeater {
        model: grid.activeWidgets

        Loader {
            active: true
            asynchronous: false
            sourceComponent: modelData.comp
            Layout.fillWidth: true
            Layout.preferredHeight: 80 * grid.uiScale
        }
    }
}
