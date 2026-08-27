import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: batteryCard
    property real uiScale: 1.0

    Layout.fillWidth: true
    implicitWidth: batteryRow.implicitWidth
    implicitHeight: batteryRow.implicitHeight
    visible: BatteryService.hasBattery

    RowLayout {
        id: batteryRow
        width: parent.width - (30 * batteryCard.uiScale)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 15 * batteryCard.uiScale

        LucideIcon {
            Layout.alignment: Qt.AlignVCenter
            color: (BatteryService.percentage <= 15 && !BatteryService.isCharging) ? Theme.color1 : Theme.selected
            size: 34 * batteryCard.uiScale
            icon: Icons.getBatteryIcon(BatteryService.percentage, BatteryService.isCharging)

            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6 * batteryCard.uiScale

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.bold: true
                    font.pixelSize: 14 * batteryCard.uiScale
                    text: "Battery"
                }
                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.pixelSize: 14 * batteryCard.uiScale
                    text: BatteryService.percentage + "%"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6 * batteryCard.uiScale
                radius: height / 2
                color: Theme.backgroundAlt

                Rectangle {
                    color: (BatteryService.percentage <= 20 && !BatteryService.isCharging) ? Theme.color1 : Theme.selected
                    height: parent.height
                    radius: height / 2
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

            Text {
                color: Theme.foreground
                font.pixelSize: 11 * batteryCard.uiScale
                opacity: 0.6
                text: BatteryService.timeText
            }
        }
    }
}
