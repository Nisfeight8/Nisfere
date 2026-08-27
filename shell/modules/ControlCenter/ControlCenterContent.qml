pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services
import "pages"
import "components"
import "widgets/SlidersCard"
import "widgets/Toggles"

Item {
    id: pageStack

    readonly property int currentIndex: ShellState.controlCenterPageIndex
    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    implicitHeight: animLoader.implicitHeight

    // ── Page Components ───────────────────────────────────
    Component {
        id: mainPageComp

        ColumnLayout {
            spacing: 10 * pageStack.uiScale

            PageTitle {
                Layout.fillWidth: true
                text: "Control Center"
                uiScale: pageStack.uiScale
            }

            Toggles {
                Layout.fillWidth: true
                uiScale: pageStack.uiScale
            }

            SlidersCard {
                Layout.fillWidth: true
                uiScale: pageStack.uiScale
            }
        }
    }

    Component {
        id: wifiPageComp
        WifiPage {
            uiScale: pageStack.uiScale
            onBackRequested: ShellState.controlCenterPageIndex = 0
        }
    }

    Component {
        id: btPageComp
        BluetoothPage {
            uiScale: pageStack.uiScale
            onBackRequested: ShellState.controlCenterPageIndex = 0
        }
    }

    Component {
        id: ethPageComp
        EthernetPage {
            uiScale: pageStack.uiScale
            onBackRequested: ShellState.controlCenterPageIndex = 0
        }
    }

    // ── Animated Loader ────────────────────────────────────
    AnimLoader {
        id: animLoader
        width: parent.width

        sourceComp: {
            switch (pageStack.currentIndex) {
            case 0:
                return mainPageComp;
            case 1:
                return wifiPageComp;
            case 2:
                return btPageComp;
            case 3:
                return ethPageComp;
            default:
                return mainPageComp;
            }
        }
    }
}
