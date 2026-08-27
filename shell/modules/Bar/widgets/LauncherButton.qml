import QtQuick
import Quickshell
import qs.core
import qs.services

BarWidget {
    id: launcherBtn

    useGradient: true

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: launcherBtn.iconSize
        text: "󰣇"
    }

    HoverHandler {
        parent: launcherBtn
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        parent: launcherBtn
        onTapped: {
            const screenName = QsWindow.window?.screen?.name;
            ShellState.toggleDashboardSearch(screenName);
        }
    }
}