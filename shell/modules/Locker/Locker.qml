import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

WlSessionLock {
    id: sessionLock
    locked: ShellState.isLocked

    WlSessionLockSurface {
        id: surface
        color: "black"

        Connections {
            target: LockerService

            function onUnlocked() {
                ShellState.isLocked = false;
            }

            function onFailed(errorMessage) {
                lockContainer.isAuthenticating = false;
                passwordInput.text = "";
                errorText.text = errorMessage;
                errorText.opacity = 1;
                passwordInput.hasError = true;
                passwordInput.forceActiveFocus();
                errorTimer.restart();
            }
        }

        Timer {
            id: errorTimer
            interval: 2500
            onTriggered: {
                errorText.opacity = 0;
                passwordInput.hasError = false;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: passwordInput.forceActiveFocus()
        }

        Image {
            anchors.fill: parent
            source: Theme.wallpaper
            fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.5
        }

        Item {
            id: lockContainer
            anchors.fill: parent
            focus: true

            readonly property real uiScale: Theme.scaleFor(surface.screen)
            property bool isAuthenticating: false

            Keys.onEscapePressed: {
                passwordInput.text = "";
                errorText.opacity = 0;
                errorTimer.stop();
                passwordInput.hasError = false;
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 40 * lockContainer.uiScale

                // --- Clock & Date ---
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0

                    Text {
                        id: clockText
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.fontName
                        font.pixelSize: 100 * lockContainer.uiScale
                        font.bold: true
                        color: "white"

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
                        }
                        Component.onCompleted: text = Qt.formatDateTime(new Date(), "HH:mm")
                    }

                    Text {
                        id: dateText
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.fontName
                        font.pixelSize: 20 * lockContainer.uiScale
                        color: "white"
                        opacity: 0.7

                        Timer {
                            interval: 60000
                            running: true
                            repeat: true
                            onTriggered: dateText.text = Qt.formatDate(new Date(), "dddd, d MMMM")
                        }
                        Component.onCompleted: text = Qt.formatDate(new Date(), "dddd, d MMMM")
                    }
                }

                // --- User Info & Auth ---
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20 * lockContainer.uiScale

                    Item {
                        id: avatarBadge
                        width: 100 * lockContainer.uiScale
                        height: 100 * lockContainer.uiScale
                        Layout.alignment: Qt.AlignHCenter

                        // Was ThemeState.shared.avatarPath — see chat, avatar moved to
                        // its own dedicated AvatarService (FileView+JsonAdapter, same
                        // pattern as SshUsageService/GitUsageService/DockerUsageService).
                        readonly property string _avatarSource: AvatarService.hasAvatar ? "file://" + AvatarService.avatarPath : ""

                        // OpacityMask, not clip+radius — clip only ever clips to the
                        // plain rectangular bounding box in QtQuick, it ignores radius
                        // entirely for child clipping purposes, so the image was
                        // rendering square underneath despite the rounded border/
                        // background drawn around it. Same pattern already used
                        // correctly for album art in the Media tab, and just applied to
                        // SystemDrawerHeader's own avatar the same way.
                        Image {
                            id: avatarImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: avatarBadge._avatarSource
                            asynchronous: true
                            cache: false
                            visible: false
                            sourceSize.width: width * 2
                            sourceSize.height: height * 2
                        }
                        Rectangle {
                            id: avatarCircleMask
                            anchors.fill: parent
                            color: "black"
                            radius: width / 2
                            visible: false
                        }
                        OpacityMask {
                            anchors.fill: parent
                            maskSource: avatarCircleMask
                            source: avatarImage
                            visible: avatarBadge._avatarSource !== ""
                        }
                        Rectangle {
                            anchors.fill: parent
                            border.color: Theme.borderColor
                            border.width: 2
                            color: "transparent"
                            radius: width / 2
                            visible: avatarBadge._avatarSource !== ""
                        }
                        Rectangle {
                            anchors.fill: parent
                            border.color: Theme.borderColor
                            border.width: 2
                            color: Theme.backgroundAlt
                            radius: width / 2
                            visible: avatarBadge._avatarSource === ""

                            LucideIcon {
                                anchors.centerIn: parent
                                icon: "user"
                                size: 50 * lockContainer.uiScale
                                color: Theme.foreground
                            }
                        }
                    }

                    Text {
                        text: SystemInfo.username
                        font.family: Theme.fontName
                        font.pixelSize: 24 * lockContainer.uiScale
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 260 * lockContainer.uiScale
                        Layout.preferredHeight: 46 * lockContainer.uiScale

                        TextField {
                            id: passwordInput
                            property bool hasError: false

                            anchors.fill: parent
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            placeholderText: ""
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 16 * lockContainer.uiScale
                            horizontalAlignment: TextInput.AlignHCenter
                            enabled: !lockContainer.isAuthenticating

                            background: Rectangle {
                                color: Theme.backgroundAlt
                                radius: Theme.radius
                                border.color: passwordInput.hasError ? Theme.color1 : (passwordInput.activeFocus ? Theme.selected : Theme.borderColor)
                                border.width: 2

                                Behavior on border.color {
                                    AnimColor {
                                        type: Anim.FastEffects
                                    }
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 10 * lockContainer.uiScale
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20 * lockContainer.uiScale
                                height: 20 * lockContainer.uiScale
                                color: "transparent"
                                radius: width / 2

                                border.color: Theme.selected
                                border.width: 3

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 3 * lockContainer.uiScale
                                    height: 3 * lockContainer.uiScale
                                    color: Theme.foreground
                                    radius: width / 2
                                }

                                RotationAnimation on rotation {
                                    running: lockContainer.isAuthenticating
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 800
                                }

                                visible: lockContainer.isAuthenticating
                            }
                            onAccepted: {
                                if (text.length === 0)
                                    return;
                                lockContainer.isAuthenticating = true;
                                errorText.opacity = 0;
                                LockerService.authenticate(text);
                            }

                            Component.onCompleted: forceActiveFocus()

                            Text {
                                anchors.centerIn: parent
                                text: "Enter password..."
                                color: Qt.rgba(1, 1, 1, 0.4)
                                font.family: Theme.fontName
                                font.pixelSize: 16 * lockContainer.uiScale
                                visible: passwordInput.text.length === 0
                            }
                        }
                    }

                    Text {
                        id: errorText
                        Layout.alignment: Qt.AlignHCenter
                        color: Theme.color1
                        font.family: Theme.fontName
                        font.pixelSize: 13 * lockContainer.uiScale
                        opacity: 0
                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    // --- Power actions (reboot / suspend / poweroff) ──
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10 * lockContainer.uiScale
                        spacing: 16 * lockContainer.uiScale

                        CircularActionButton {
                            icon: "rotate-ccw"
                            label: "Restart"
                            onTapped: PowerService.reboot()
                        }
                        CircularActionButton {
                            icon: "moon"
                            label: "Suspend"
                            onTapped: PowerService.suspend()
                        }
                        CircularActionButton {
                            icon: "power"
                            label: "Shut Down"
                            onTapped: PowerService.poweroff()
                        }
                    }
                }
            }

            // --- Footer Widgets ---
            RowLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 60 * lockContainer.uiScale
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24 * lockContainer.uiScale

                // Weather Widget
                Rectangle {
                    width: 80 * lockContainer.uiScale
                    height: 44 * lockContainer.uiScale
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    opacity: 0.9

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8 * lockContainer.uiScale
                        LucideIcon {
                            icon: "cloud"
                            size: 20 * lockContainer.uiScale
                            color: Theme.foreground
                        }
                        Text {
                            text: Math.round(WeatherService.temperature) + "°C"
                            font.family: Theme.fontName
                            font.pixelSize: 16 * lockContainer.uiScale
                            color: Theme.foreground
                        }
                    }
                }

                // Media Widget
                Rectangle {
                    visible: MediaService.hasPlayer
                    width: 280 * lockContainer.uiScale
                    height: 44 * lockContainer.uiScale
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    opacity: 0.9

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12 * lockContainer.uiScale
                        spacing: 12 * lockContainer.uiScale

                        LucideIcon {
                            icon: "music"
                            size: 18 * lockContainer.uiScale
                            color: Theme.selected
                        }

                        Text {
                            Layout.fillWidth: true
                            text: MediaService.title
                            font.family: Theme.fontName
                            font.pixelSize: 13 * lockContainer.uiScale
                            color: Theme.foreground
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 12 * lockContainer.uiScale
                            LucideIcon {
                                icon: "skip-back"
                                size: 18 * lockContainer.uiScale
                                color: Theme.foreground

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: MediaService.previous()
                                }
                            }
                            LucideIcon {
                                icon: MediaService.isPlaying ? "pause" : "play"
                                size: 18 * lockContainer.uiScale
                                color: Theme.foreground

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: MediaService.togglePlayPause()
                                }
                            }
                            LucideIcon {
                                icon: "skip-forward"
                                size: 18 * lockContainer.uiScale
                                color: Theme.foreground

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: MediaService.next()
                                }
                            }
                        }
                    }
                }

                // Keyboard Layout Widget
                Rectangle {
                    width: 80 * lockContainer.uiScale
                    height: 44 * lockContainer.uiScale
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    opacity: 0.9

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8 * lockContainer.uiScale
                        LucideIcon {
                            icon: "keyboard"
                            size: 18 * lockContainer.uiScale
                            color: Theme.foreground
                        }
                        Text {
                            text: KeyboardService.currentLayout.toUpperCase()
                            font.family: Theme.fontName
                            font.pixelSize: 16 * lockContainer.uiScale
                            font.bold: true
                            color: Theme.foreground
                        }
                    }
                }
            }
        }
    }
}
