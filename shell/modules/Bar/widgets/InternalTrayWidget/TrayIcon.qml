import QtQuick
import qs.core
import qs.services

Item {
    id: root

    property string iconName: ""
    property string infoText: ""
    property string tooltipText: ""
    property int iconSize: 16
    property real fontSize: 14

    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    Row {
        id: contentRow
        spacing: 6
        anchors.centerIn: parent

        LucideIcon {
            icon: root.iconName
            size: root.iconSize
            color: Theme.foreground
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.infoText !== ""
            text: root.infoText
            font.family: Theme.fontName
            font.pixelSize: root.fontSize
            color: Theme.foreground
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    BarTooltip {
        showPopup: hoverHandler.hovered && !ShellState.controlCenterOpened && root.tooltipText !== ""
        targetItem: root
        text: root.tooltipText
    }
}
