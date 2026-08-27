pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // ── Public signals ────────────────────────────────────────────
    signal wifiConnected(string ssid)
    signal wifiDisconnected
    signal ethernetConnected(string details)
    signal ethernetDisconnected

    // ── Hardware scan ─────────────────────────────────────────────
    property Connections _devicesConnections: Connections {
        target: Networking.devices
        function onValuesChanged() {
            root.scanHardware();
        }
    }

    property alias ethernet: ethernetService
    readonly property string ethernetName: ethernet.statusName
    readonly property bool hasEthernet: ethernet.available
    readonly property bool hasWifi: wifi.available
    readonly property bool isEthernetConnected: ethernet.connected
    readonly property bool isWifiConnected: wifi.connected
    property alias wifi: wifiService
    property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property string wifiName: wifi.statusName

    function scanHardware() {
        if (!Networking.devices?.values)
            return;
        let foundWifi = null, foundEth = null;
        for (let dev of Networking.devices.values) {
            if (dev.type === DeviceType.Wifi && !foundWifi) {
                foundWifi = dev;
                dev.scannerEnabled = true;
            }
            if (dev.type === DeviceType.Wired && !foundEth)
                foundEth = dev;
            if (foundWifi && foundEth)
                break;
        }
        wifiService.device = foundWifi;
        ethernetService.device = foundEth;
    }

    Component.onCompleted: root.scanHardware()

    // ── Ethernet sub-service ──────────────────────────────────────
    property QtObject _ethernetService: QtObject {
        id: ethernetService

        property QtObject device: null
        readonly property bool available: !!device
        readonly property bool connected: device ? device.connected : false
        readonly property bool hasLink: device ? device.hasLink : false
        readonly property int linkSpeed: device ? device.linkSpeed : 0
        readonly property QtObject network: device ? device.network : null

        readonly property string statusName: {
            if (!device)
                return "No hardware";
            if (!hasLink)
                return "Cable disconnected";
            if (device.connected)
                return "Connected (" + linkSpeed + " Mbps)";
            if (device.state === ConnectionState.Connecting)
                return "Connecting...";
            return "Disconnected";
        }

        property Connections _signalTrigger: Connections {
            target: ethernetService.device
            ignoreUnknownSignals: true
            function onConnectedChanged() {
                if (ethernetService.device.connected)
                    root.ethernetConnected(ethernetService.statusName);
                else
                    root.ethernetDisconnected();
            }
        }

        function connect() {
            network?.connect();
        }
        function disconnect() {
            network?.disconnect();
        }
        function toggle() {
            connected ? disconnect() : connect();
        }
    }

    // ── Wi-Fi sub-service ─────────────────────────────────────────
    property QtObject _wifiService: QtObject {
        id: wifiService

        property QtObject pendingNetwork: null
        signal errorOccurred(string ssid, string errorMessage)

        property QtObject device: null
        readonly property bool available: !!device
        readonly property bool connected: device ? device.connected : false

        readonly property var _connectedNetwork: {
            if (!device || !device.networks || !device.networks.values)
                return null;
            for (const net of device.networks.values) {
                if (net && net.connected)
                    return net;
            }
            return null;
        }
        readonly property double netStrength: _connectedNetwork ? _connectedNetwork.signalStrength : 0

        // Connected network always first; the rest ordered by
        // strongest signal first — was living duplicated in
        // WifiPage.qml as a page-local computed property, moved here
        // since it's derived straight from device.networks (real
        // state, not page concern) and any future consumer (a bar
        // quick-picker, a ControlCenter compact view, ...) would want
        // the exact same ordering rather than reimplementing it.
        // Reads net.connected/net.signalStrength for every network
        // inside this binding, same reactive pattern as
        // _connectedNetwork above — recomputes correctly whenever any
        // network's connection state OR signal strength changes, no
        // manual Connections wiring needed.
        readonly property var sortedNetworks: {
            if (!device || !device.networks || !device.networks.values)
                return [];
            const nets = device.networks.values.slice();
            nets.sort((a, b) => {
                if (a.connected !== b.connected)
                    return a.connected ? -1 : 1;
                return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
            });
            return nets;
        }

        readonly property string statusName: {
            if (!device)
                return "No hardware";
            if (!Networking.wifiEnabled)
                return "Closed";
            if (!device.connected)
                return (device.state === ConnectionState.Connecting) ? "Connecting..." : "Disconnected";
            if (_connectedNetwork)
                return _connectedNetwork.name;
            return "Connected";
        }

        property Connections _signalTrigger: Connections {
            target: wifiService.device
            ignoreUnknownSignals: true
            function onConnectedChanged() {
                if (wifiService.device.connected)
                    root.wifiConnected(wifiService.statusName);
                else
                    root.wifiDisconnected();
            }
        }

        property Connections _pendingConn: Connections {
            target: wifiService.pendingNetwork
            ignoreUnknownSignals: true
            function onConnectionFailed(reason) {
                if (!wifiService.pendingNetwork)
                    return;
                const ssid = wifiService.pendingNetwork.name;

                let message;
                let shouldForget = false;
                switch (reason) {
                case ConnectionFailReason.NoSecrets:
                    message = "Wrong Password";
                    shouldForget = true;
                    break;
                case ConnectionFailReason.WifiNetworkLost:
                    message = "Network out of range";
                    break;
                case ConnectionFailReason.WifiAuthTimeout:
                    message = "Authentication timed out — try again";
                    break;
                case ConnectionFailReason.WifiClientFailed:
                case ConnectionFailReason.WifiClientDisconnected:
                    message = "Wi-Fi connection failed — try again";
                    break;
                default:
                    message = "Connection failed — try again";
                }

                if (shouldForget)
                    wifiService.pendingNetwork.forget();
                wifiService.pendingNetwork = null;
                wifiService.errorOccurred(ssid, message);
            }
            function onConnectedChanged() {
                if (wifiService.pendingNetwork?.connected)
                    wifiService.pendingNetwork = null;
            }
        }

        function connectTo(ssid, password = "") {
            if (!device?.networks?.values)
                return;
            for (let net of device.networks.values) {
                if (net.name === ssid) {
                    pendingNetwork = net;
                    password !== "" ? net.connectWithPsk(password) : net.connect();
                    return;
                }
            }
        }
        function disconnect() {
            device?.disconnect();
        }
        function toggle() {
            Networking.wifiEnabled = !Networking.wifiEnabled;
        }
        function forgetNetwork(ssid) {
            if (!device?.networks?.values)
                return;
            for (let net of device.networks.values)
                if (net.name === ssid) {
                    net.forget();
                    return;
                }
        }
    }
}
