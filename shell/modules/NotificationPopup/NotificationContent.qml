pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

Item {
    id: content

    required property var currentNotif
    required property real notifProgress
    required property bool isCritical
    required property bool hasImage
    required property bool hasAppIcon
    required property bool hasActions

    readonly property bool hasNotif: currentNotif !== null

    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    signal dismissRequested
    signal actionInvoked(var action)

    implicitWidth: 350 * uiScale
    implicitHeight: mainColumn.implicitHeight + (30 * uiScale)

    ColumnLayout {
        id: mainColumn
        anchors {
            fill: parent
            margins: 7 * content.uiScale
        }
        spacing: 12 * content.uiScale

        // ── Progress bar ──────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 3 * content.uiScale

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                color: Theme.selected
                width: parent.width * content.notifProgress
                radius: height / 2
            }
        }

        // ── Main row: icon + text ─────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 13 * content.uiScale

            Rectangle {
                id: iconBadge
                readonly property real _size: (content.hasImage ? 80 : 36) * content.uiScale
                readonly property string _imageSource: {
                    if (content.hasAppIcon)
                        return content.currentNotif.nAppIcon;
                    if (content.hasImage)
                        return content.currentNotif.nImage;
                    return "";
                }

                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: _size
                Layout.preferredHeight: _size
                border.color: Theme.borderColor
                border.width: Theme.widgetBorderWidth
                color: Theme.backgroundAlt
                radius: Theme.radius * 1.2

                LucideIcon {
                    anchors.centerIn: parent
                    icon: content.isCritical ? "triangle-alert" : "bell"
                    color: content.isCritical ? Theme.color1 : Theme.selected
                    size: 24 * content.uiScale
                    visible: !content.hasAppIcon && !content.hasImage
                }

                Image {
                    anchors {
                        fill: parent
                        margins: content.hasImage ? 0 : (8 * content.uiScale)
                    }
                    fillMode: Image.PreserveAspectCrop
                    source: iconBadge._imageSource
                    asynchronous: true
                    sourceSize.width: iconBadge._size
                    sourceSize.height: iconBadge._size
                    visible: iconBadge._imageSource !== ""

                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                spacing: 4 * content.uiScale

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: content.hasNotif ? content.currentNotif.nAppName.toUpperCase() : ""
                        color: content.isCritical ? Theme.color1 : Theme.selected
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 12 * content.uiScale
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: content.hasNotif ? content.currentNotif.timeReceived : ""
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 11 * content.uiScale
                        opacity: 0.6
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 4 * content.uiScale
                        icon: "x"
                        size: 24 * content.uiScale
                        iconSize: 14 * content.uiScale
                        radius: size / 2
                        hoverSolid: true
                        hoverColor: Theme.color1
                        contrastColor: Theme.background
                        fixedIconColor: Theme.foreground
                        idleOpacity: 0.6
                        onTapped: {
                            if (content.hasNotif)
                                NotificationService.dismissNotification(content.currentNotif);
                            content.dismissRequested();
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: content.hasNotif ? content.currentNotif.nSummary : ""
                    color: Theme.foreground
                    elide: Text.ElideRight
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 15 * content.uiScale
                }

                Text {
                    Layout.fillWidth: true
                    text: content.hasNotif ? content.currentNotif.nBody : ""
                    color: Theme.foreground
                    elide: Text.ElideRight
                    font.family: Theme.fontName
                    font.pixelSize: 13 * content.uiScale
                    maximumLineCount: 3
                    opacity: 0.8
                    wrapMode: Text.Wrap
                }
            }
        }

        // ── Actions ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * content.uiScale
            visible: content.hasActions

            Repeater {
                model: content.hasActions ? content.currentNotif.actions : []

                delegate: Rectangle {
                    id: actionBtn
                    readonly property bool isHovered: hover.hovered
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36 * content.uiScale
                    radius: Theme.radius
                    border.width: 1
                    border.color: Theme.borderColor
                    color: isHovered ? Theme.selected : "transparent"
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.text
                        color: actionBtn.isHovered ? Theme.background : Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 12 * content.uiScale
                        Behavior on color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            content.actionInvoked(modelData);
                            if (content.hasNotif) {
                                const notif = content.currentNotif;
                                Qt.callLater(() => NotificationService.dismissNotification(notif));
                            }
                        }
                    }
                }
            }
        }
    }
}
