import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

BarWidget {
    id: kbWidget

    useGradient: true

    property bool popupOpened: false

    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter
        LucideIcon {
            size: kbWidget.iconSize
            color: Theme.selected
            icon: "keyboard"
        }
        Text {
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: kbWidget.fontSize
            text: KeyboardService.getShort(KeyboardService.currentLayout)
        }
    }

    HoverHandler {
        parent: kbWidget
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        parent: kbWidget
        onTapped: kbWidget.popupOpened = !kbWidget.popupOpened
    }

    BarPopup {
        id: kbPopup

        showPopup: kbWidget.popupOpened
        targetItem: kbWidget

        ColumnLayout {
            spacing: 10 * kbPopup.uiScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * kbPopup.uiScale

                LucideIcon {
                    size: 20 * kbPopup.uiScale
                    color: Theme.selected
                    icon: "keyboard"
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 14 * kbPopup.uiScale
                    text: "Keyboard Layout"
                }
            }
            Rectangle {
                Layout.fillWidth: true
                color: Theme.backgroundAlt
                height: 1
                opacity: 0.8
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * kbPopup.uiScale

                Repeater {
                    model: KeyboardService.availableLayouts

                    delegate: Rectangle {
                        id: layoutDelegate

                        readonly property bool isCurrent: KeyboardService.getShort(KeyboardService.currentLayout) === KeyboardService.getShort(modelData.toLowerCase())
                        readonly property bool isHovered: itemHover.hovered

                        Layout.fillWidth: true
                        Layout.preferredHeight: 32 * kbPopup.uiScale
                        color: isHovered ? Theme.backgroundAlt : "transparent"
                        radius: 6 * kbPopup.uiScale

                        Behavior on color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8 * kbPopup.uiScale
                            spacing: 10 * kbPopup.uiScale

                            Text {
                                Layout.fillWidth: true
                                color: layoutDelegate.isCurrent ? Theme.selected : Theme.foreground
                                font.bold: layoutDelegate.isCurrent
                                font.family: Theme.fontName
                                font.pixelSize: 13 * kbPopup.uiScale
                                text: KeyboardService.getFull(modelData)

                                Behavior on color {
                                    AnimColor {
                                        type: Anim.FastEffects
                                    }
                                }
                            }
                            LucideIcon {
                                color: Theme.selected
                                size: 14 * kbPopup.uiScale
                                icon: "check"
                                visible: layoutDelegate.isCurrent
                            }
                        }

                        HoverHandler {
                            id: itemHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: {
                                KeyboardService.changeLayout(index);
                                kbWidget.popupOpened = false;
                            }
                        }
                    }
                }
            }
            Item {
                Layout.fillHeight: true
            }
        }
    }
}
