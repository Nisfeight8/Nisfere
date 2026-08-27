import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

BarWidget {
    id: root

    visible: BatteryService.hasBattery
    spacing: 8
    useGradient: true
    readonly property bool isCritical: !BatteryService.isCharging && BatteryService.percentage <= 15
    readonly property color statusColor: BatteryService.isCharging ? Theme.selected : (isCritical ? Theme.color1 : Theme.foreground)

    property bool popupOpen: false
    property bool popupContentHovered: false
    readonly property bool anyHovered: hover.hovered || root.popupContentHovered

    onAnyHoveredChanged: {
        if (anyHovered) {
            closeTimer.stop();
            popupOpen = true;
        }
    }

    Timer {
        id: closeTimer
        interval: 150
        running: !root.anyHovered && root.popupOpen
        onTriggered: root.popupOpen = false
    }

    // ── Compact bar display — icon + percentage ────────────────────
    LucideIcon {
        id: battIcon
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.getBatteryIcon(BatteryService.percentage, BatteryService.isCharging)
        size: root.iconSize
        color: root.statusColor
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }

        SequentialAnimation on opacity {
            running: root.isCritical
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.4
                duration: 700
            }
            NumberAnimation {
                to: 1.0
                duration: 700
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: BatteryService.percentage + "%"
        color: root.statusColor
        font.family: Theme.fontName
        font.pixelSize: root.fontSize
        font.bold: BatteryService.isCharging || root.isCritical
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

    // ── Rich detail popup — icon badge, %, status, progress, time ──
    BarPopup {
        id: batteryPopup
        showPopup: root.popupOpen
        targetItem: root

        contentComponent: Component {
            ColumnLayout {
                spacing: 12 * batteryPopup.uiScale

                HoverHandler {
                    enabled: root.popupOpen
                    onHoveredChanged: root.popupContentHovered = hovered
                }

                RowLayout {
                    spacing: 12 * batteryPopup.uiScale

                    Rectangle {
                        width: 48 * batteryPopup.uiScale
                        height: 48 * batteryPopup.uiScale
                        radius: width / 2
                        color: Theme.backgroundAlt
                        border.width: 1
                        border.color: Theme.borderColor

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: Icons.getBatteryIcon(BatteryService.percentage, BatteryService.isCharging)
                            size: 24 * batteryPopup.uiScale
                            color: root.statusColor
                        }
                    }

                    ColumnLayout {
                        spacing: 2 * batteryPopup.uiScale

                        Text {
                            text: BatteryService.percentage + "%"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 22 * batteryPopup.uiScale
                            font.bold: true
                        }
                        Text {
                            text: BatteryService.stateName
                            color: root.statusColor
                            font.family: Theme.fontName
                            font.pixelSize: 12 * batteryPopup.uiScale
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6 * batteryPopup.uiScale
                    radius: height / 2
                    color: Theme.backgroundAlt

                    Rectangle {
                        height: parent.height
                        radius: height / 2
                        color: root.statusColor
                        width: parent.width * (BatteryService.percentage / 100)
                        Behavior on width {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                        Behavior on color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6 * batteryPopup.uiScale

                    LucideIcon {
                        icon: "clock-3"
                        size: 13 * batteryPopup.uiScale
                        color: Theme.foreground
                        opacity: 0.6
                    }
                    Text {
                        Layout.fillWidth: true
                        text: BatteryService.timeText
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 12 * batteryPopup.uiScale
                        opacity: 0.75
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
