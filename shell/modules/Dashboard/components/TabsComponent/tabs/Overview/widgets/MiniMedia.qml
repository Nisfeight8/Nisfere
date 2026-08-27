import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

GlassCard {
    id: miniMedia
    property real uiScale: 1.0

    // Same reasoning as MiniWeather.baseCardWidth — rightColumn reads
    // this to help decide its own width, so it can't be derived from
    // miniMedia's own actual size.
    readonly property real baseCardWidth: 400
    implicitWidth: baseCardWidth * uiScale

    anchors.fill: parent

    readonly property real refSize: Math.min(miniMedia.width, miniMedia.height)

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Math.max(10, miniMedia.refSize * 0.1)
        spacing: Math.max(10, miniMedia.refSize * 0.1)

        Rectangle {
            id: album
            readonly property real artSize: Math.max(60, miniMedia.refSize * 0.8)
            Layout.preferredWidth: artSize
            Layout.preferredHeight: artSize
            clip: true
            color: Theme.background
            radius: Theme.radius - 4
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: MediaService.albumArt
                visible: MediaService.albumArt !== ""
                asynchronous: true
                cache: false
                sourceSize.width: album.artSize * 2
                sourceSize.height: album.artSize * 2
            }
            LucideIcon {
                anchors.centerIn: parent
                icon: "music"
                size: Math.max(24, parent.width * 0.4)
                color: Theme.foreground
                opacity: 0.5
                visible: MediaService.albumArt === ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2 * miniMedia.uiScale

            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: MediaService.title
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(14, miniMedia.refSize * 0.15)
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: MediaService.artist !== "" ? MediaService.artist : "Unknown Artist"
                color: Theme.foreground
                elide: Text.ElideRight
                font.family: Theme.fontName
                font.pixelSize: Math.max(11, miniMedia.refSize * 0.12)
                opacity: 0.7
            }

            Item {
                Layout.fillHeight: true
            }

            MediaSlider {
                id: miniMediaSlider
                Layout.fillWidth: true
                trackColor: Theme.background
            }

            Item {
                Layout.fillHeight: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 20 * miniMedia.uiScale

                IconButton {
                    icon: "skip-back"
                    flat: true
                    size: Math.max(18, miniMedia.refSize * 0.18)
                    iconSize: Math.max(18, miniMedia.refSize * 0.18)
                    fixedIconColor: Theme.foreground
                    idleOpacity: 0.7
                    onTapped: MediaService.previous()
                }

                IconButton {
                    id: playBtn
                    icon: MediaService.isPlaying ? "pause" : "play"
                    flat: true
                    size: Math.max(20, miniMedia.refSize * 0.20)
                    iconSize: Math.max(20, miniMedia.refSize * 0.20)
                    fixedIconColor: Theme.selected
                    dimWhenIdle: false
                    scale: pressed ? 0.9 : 1.0

                    Behavior on scale {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                    onTapped: MediaService.togglePlayPause()
                }

                IconButton {
                    icon: "skip-forward"
                    flat: true
                    size: Math.max(18, miniMedia.refSize * 0.18)
                    iconSize: Math.max(18, miniMedia.refSize * 0.18)
                    fixedIconColor: Theme.foreground
                    idleOpacity: 0.7
                    onTapped: MediaService.next()
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
