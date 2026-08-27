import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    // Was ThemeState.shared.avatarPath — the avatar is user-specific,
    // pure client-side "remember one string" state, no reason to be
    // routed through ThemeState's shared/shell settings machinery.
    // See chat: AvatarService (FileView+JsonAdapter, same pattern as
    // SshUsageService/GitUsageService/DockerUsageService) is the
    // dedicated home for it now.
    readonly property string _avatarSource: AvatarService.hasAvatar ? "file://" + AvatarService.avatarPath : ""

    ColumnLayout {
        id: col
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10 * root.uiScale

        // ── User row ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 14 * root.uiScale

            // Avatar — OpacityMask, not clip+radius (clip only ever
            // clips to the plain rectangular bounding box in QtQuick,
            // it ignores radius entirely for child clipping purposes
            // — the image was rendering square underneath despite the
            // rounded border/background around it). Same pattern
            // already used correctly for album art in the Media tab.
            Item {
                width: 56 * root.uiScale
                height: 56 * root.uiScale

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: root._avatarSource
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
                    visible: root._avatarSource !== ""
                }
                Rectangle {
                    anchors.fill: parent
                    border.color: Theme.borderColor
                    border.width: 2
                    color: "transparent"
                    radius: width / 2
                    visible: root._avatarSource !== ""
                }
                Rectangle {
                    anchors.fill: parent
                    border.color: Theme.borderColor
                    border.width: 2
                    color: Theme.backgroundAlt
                    radius: width / 2
                    visible: root._avatarSource === ""

                    LucideIcon {
                        anchors.centerIn: parent
                        icon: "user"
                        size: 26 * root.uiScale
                        color: Theme.selected
                    }
                }
            }

            // Username + uptime
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * root.uiScale
                Text {
                    text: SystemInfo.username
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 20 * root.uiScale
                    font.bold: true
                }
                RowLayout {
                    spacing: 5 * root.uiScale
                    LucideIcon {
                        icon: "clock-3"
                        size: 12 * root.uiScale
                        color: Theme.selected
                    }
                    Text {
                        text: SystemInfo.uptime
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 12 * root.uiScale
                        opacity: 0.6
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 10 * root.uiScale
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                IconButton {
                    icon: "settings"
                    size: 32 * root.uiScale
                    iconSize: 16 * root.uiScale
                    radius: Theme.radius
                    hoverColor: Theme.selected
                    activeColor: Theme.color2
                    normalColor: Theme.backgroundAlt
                    idleOpacity: 0.4
                    tooltipText: "Open Settings Menu"
                    onTapped: {
                        ShellState.openDashboardComponent(ShellState.focusedScreenName, "settings");
                        ShellState.systemDrawerOpened = false;
                    }
                }

                IconButton {
                    icon: "power"
                    size: 32 * root.uiScale
                    iconSize: 16 * root.uiScale
                    radius: Theme.radius
                    hoverColor: Theme.color1
                    activeColor: Theme.color1
                    normalColor: Theme.backgroundAlt
                    idleOpacity: 0.4
                    tooltipText: "Open Power Menu"
                    onTapped: ShellState.powerMenuOpened = true
                }
            }
        }

        // ── OS info strip ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 30 * root.uiScale
            radius: Theme.radius
            color: Theme.backgroundAlt

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12 * root.uiScale
                    rightMargin: 12 * root.uiScale
                }
                spacing: 8 * root.uiScale
                LucideIcon {
                    icon: "box"
                    size: 18 * root.uiScale
                    color: Theme.selected
                }
                Text {
                    text: SystemInfo.osName
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                    opacity: 0.85
                }
                Rectangle {
                    width: 1
                    height: 10 * root.uiScale
                    color: Theme.borderColor
                    opacity: 0.5
                }
                LucideIcon {
                    icon: "layout-dashboard"
                    size: 18 * root.uiScale
                    color: Theme.selected
                }
                Text {
                    text: SystemInfo.windowManager
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                    opacity: 0.85
                }
            }
        }
    }
}
