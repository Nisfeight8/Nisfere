import QtQuick
import qs.core
import qs.services

BarWidget {
    id: root

    visible: ScreenRecordService.isRecording
    bgColor: hover.hovered ? Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.12) : "transparent"
    spacing: 6

    Behavior on bgColor {
        AnimColor {
            type: Anim.FastEffects
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(6, root.iconSize * 0.4)
        height: width
        radius: width / 2
        color: Theme.color1

        SequentialAnimation on opacity {
            running: ScreenRecordService.isRecording
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.25
                duration: 650
            }
            NumberAnimation {
                to: 1.0
                duration: 650
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: ScreenRecordService.formatDuration()
        color: Theme.color1
        font.family: Theme.fontName
        font.pixelSize: root.fontSize
        font.bold: true
    }

    HoverHandler {
        id: hover
        parent: root
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        parent: root
        onTapped: ScreenRecordService.stop()
    }

    BarTooltip {
        showPopup: hover.hovered
        targetItem: root
        text: "Recording — click to stop"
    }
}
