import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core

GlassCard {
    id: card

    required property var notif
    property real cardHeight: 85
    property real iconSize: 40
    property real fontSizeTitle: 14
    property real fontSizeBody: 11
    property real uiScale: 1.0

    signal closeRequested

    readonly property bool isHovered: cardHover.hovered
    readonly property color accentColor: notif.isCritical ? Theme.color1 : Theme.selected

    height: cardHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, card.isHovered ? 0.04 : 0)
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 8 * card.uiScale
        width: 3 * card.uiScale
        radius: width / 2
        color: card.accentColor
        opacity: 0.8
    }

    HoverHandler {
        id: cardHover
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12 * card.uiScale
        anchors.leftMargin: 20 * card.uiScale   // extra room for the accent bar
        spacing: 14 * card.uiScale

        // App icon / notification icon
        Rectangle {
            Layout.preferredWidth: card.iconSize
            Layout.preferredHeight: card.iconSize
            radius: Theme.radius
            color: Theme.background
            border.width: 1
            border.color: Theme.borderColor
            clip: true

            LucideIcon {
                anchors.centerIn: parent
                size: card.iconSize * 0.8
                icon: notif.isCritical ? "triangle-alert" : "bell"
                color: card.accentColor
                visible: !notif.nAppIcon && !notif.nImage
            }

            Image {
                id: notifImage
                anchors.fill: parent
                anchors.margins: 4 * card.uiScale
                fillMode: Image.PreserveAspectFit
                source: notif.nAppIcon || notif.nImage || ""
                asynchronous: true
                cache: true
                visible: false
                sourceSize.width: card.iconSize
                sourceSize.height: card.iconSize
            }
            Rectangle {
                id: notifImageMask
                anchors.fill: notifImage
                radius: Theme.radius - (4 * card.uiScale)
                visible: false
            }
            OpacityMask {
                anchors.fill: notifImage
                source: notifImage
                maskSource: notifImageMask
                visible: notifImage.source !== ""
            }
        }

        // Text content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2 * card.uiScale

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: (notif.nAppName || "SYSTEM").toUpperCase()
                    color: card.accentColor
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: card.fontSizeTitle
                    opacity: 0.8
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: notif.timeReceived || ""
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: card.fontSizeTitle
                    opacity: 0.4
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: notif.nSummary || ""
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: card.fontSizeTitle + (2 * card.uiScale)
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: notif.nBody || ""
                color: Theme.foreground
                elide: Text.ElideRight
                font.family: Theme.fontName
                font.pixelSize: card.fontSizeBody
                maximumLineCount: 1
                opacity: 0.6
            }
        }

        // Close button
        IconButton {
            icon: "x"
            size: 28 * card.uiScale
            iconSize: 14 * card.uiScale
            normalColor: Theme.backgroundAlt
            radius: Theme.radius
            hoverColor: Theme.color1
            opacity: card.isHovered ? 1 : 0.35
            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
            onTapped: card.closeRequested()
        }
    }
}
