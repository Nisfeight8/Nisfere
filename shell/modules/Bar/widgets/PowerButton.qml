import QtQuick
import qs.core
import qs.services

BarWidget {
    id: powererBtn
    useGradient: true
    paddingX: 14

    LucideIcon {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        size: powererBtn.iconSize
        icon: "power"
    }

    HoverHandler {
        parent: powererBtn
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        parent: powererBtn
        onTapped: ShellState.powerMenuOpened = !ShellState.powerMenuOpened
    }
}