import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

BarWidget {
    id: audioWidget

    property bool popupOpened: false

    useGradient: true

    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter
        LucideIcon {
            id: volumeIcon
            color: AudioService.muted ? Theme.color1 : Theme.selected
            size: audioWidget.iconSize
            icon: Icons.getVolumeIcon(AudioService.volume, AudioService.muted)

            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
        Text {
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: audioWidget.fontSize
            text: Math.round(AudioService.volume * 100) + "%"
        }
    }
    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        LucideIcon {
            color: AudioService.sourceMuted ? Theme.color1 : Theme.selected
            size: audioWidget.iconSize
            icon: Icons.getMicIcon(AudioService.sourceMuted)

            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
        }

        Text {
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: audioWidget.fontSize
            text: Math.round(AudioService.sourceVolume * 100) + "%"
        }
    }

    HoverHandler {
        parent: audioWidget
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        parent: audioWidget
        onTapped: audioWidget.popupOpened = !audioWidget.popupOpened
    }
    MouseArea {
        parent: audioWidget
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => {
            const step = 0.05;
            const delta = wheel.angleDelta.y > 0 ? step : -step;
            AudioService.setVolume(Math.max(0, Math.min(1, AudioService.volume + delta)));
        }
    }

    BarPopup {
        id: audioPopup

        showPopup: audioWidget.popupOpened
        targetItem: audioWidget

        ColumnLayout {
            implicitWidth: 260 * audioPopup.uiScale
            spacing: 12 * audioPopup.uiScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * audioPopup.uiScale

                LucideIcon {
                    color: Theme.selected
                    size: 20 * audioPopup.uiScale
                    icon: "book-headphones"
                }
                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 14 * audioPopup.uiScale
                    text: "Audio Settings"
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
                spacing: 4 * audioPopup.uiScale

                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 10 * audioPopup.uiScale
                    opacity: 0.5
                    text: "OUTPUT DEVICE"
                }
                RowLayout {
                    spacing: 10 * audioPopup.uiScale

                    LucideIcon {
                        id: outputMuteIcon
                        color: AudioService.muted ? Theme.color1 : Theme.foreground
                        size: 16 * audioPopup.uiScale
                        icon: AudioService.muted ? "volume-x" : "volume-2"

                        Behavior on color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: AudioService.toggleMute()
                        }
                    }
                    CustomSlider {
                        id: outputSlider
                        Layout.fillWidth: true
                        uiScale: audioPopup.uiScale

                        Binding {
                            target: outputSlider
                            property: "value"
                            value: AudioService.volume
                            when: !outputSlider.pressed
                            restoreMode: Binding.RestoreNone
                        }

                        onMoved: AudioService.setVolume(value)
                    }
                    Text {
                        Layout.preferredWidth: 35 * audioPopup.uiScale
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 12 * audioPopup.uiScale
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(AudioService.volume * 100) + "%"
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * audioPopup.uiScale

                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 10 * audioPopup.uiScale
                    opacity: 0.5
                    text: "INPUT DEVICE"
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10 * audioPopup.uiScale

                    RowLayout {
                        spacing: 6 * audioPopup.uiScale

                        LucideIcon {
                            Layout.alignment: Qt.AlignVCenter
                            color: AudioService.sourceMuted ? Theme.color1 : Theme.foreground
                            size: 16 * audioPopup.uiScale
                            icon: Icons.getMicIcon(AudioService.sourceMuted)

                            Behavior on color {
                                AnimColor {
                                    type: Anim.FastEffects
                                }
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: AudioService.toggleSourceMute()
                            }
                        }
                    }
                    CustomSlider {
                        id: inputSlider
                        Layout.fillWidth: true
                        uiScale: audioPopup.uiScale

                        Binding {
                            target: inputSlider
                            property: "value"
                            value: AudioService.sourceVolume
                            when: !inputSlider.pressed
                            restoreMode: Binding.RestoreNone
                        }

                        onMoved: AudioService.setSourceVolume(value)
                    }
                    Text {
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 12 * audioPopup.uiScale
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(AudioService.sourceVolume * 100) + "%"
                    }
                }
            }
            Item {
                Layout.fillHeight: true
            }
        }
    }
}
