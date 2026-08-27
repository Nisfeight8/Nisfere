import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    readonly property var shared: ThemeState.shared
    readonly property var shell: ThemeState.shell

    property string _pendingKey: ""
    property var _pendingValue: null
    property string _pendingScope: "shared"
    property Timer _debounceTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: ThemeActions.setSetting(root._pendingKey, root._pendingValue, root._pendingScope)
    }
    function _debouncedSet(key, value, scope) {
        root._pendingKey = key;
        root._pendingValue = value;
        root._pendingScope = scope;
        root._debounceTimer.restart();
    }

    // Native OS file picker for choosing an avatar image — see chat
    // for why a real FileDialog rather than reusing the shell's own
    // @files search provider here. selectedFile comes back as a
    // file:// URL, not a plain path; AvatarService.setAvatarFromUrl
    // handles that conversion.
    FileDialog {
        id: avatarDialog
        title: "Choose profile picture"
        currentFolder: "file://" + Quickshell.env("HOME") + "/Pictures"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        fileMode: FileDialog.OpenFile
        onAccepted: AvatarService.setAvatarFromUrl(selectedFile)
    }

    CustomScrollView {
        anchors.fill: parent
        clip: true
        uiScale: root.uiScale

        ColumnLayout {
            width: parent.width
            spacing: 24 * root.uiScale

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4 * root.uiScale
            }

            // ── Profile ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                Text {
                    text: "Profile"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14 * root.uiScale

                    Rectangle {
                        width: 64 * root.uiScale
                        height: 64 * root.uiScale
                        radius: width / 2
                        color: Theme.backgroundAlt
                        border.width: 1
                        border.color: Theme.borderColor
                        clip: true

                        Image {
                            anchors.fill: parent
                            visible: AvatarService.hasAvatar
                            source: AvatarService.hasAvatar ? AvatarService.avatarPath : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        LucideIcon {
                            anchors.centerIn: parent
                            visible: !AvatarService.hasAvatar
                            icon: "user"
                            size: 28 * root.uiScale
                            color: Theme.foreground
                            opacity: 0.4
                        }
                    }

                    ColumnLayout {
                        spacing: 6 * root.uiScale

                        Text {
                            text: "Profile Picture"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: "Shown on the lock screen and system drawer"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 10 * root.uiScale
                            opacity: 0.5
                        }
                        RowLayout {
                            spacing: 8 * root.uiScale

                            NavTile {
                                icon: "image"
                                label: "Choose..."
                                uiScale: root.uiScale
                                Layout.preferredWidth: 110 * root.uiScale
                                Layout.preferredHeight: 32 * root.uiScale
                                onTapped: {
                                    ShellState.closeDashboard();
                                    avatarDialog.open();
                                }
                            }
                            IconButton {
                                icon: "x"
                                size: 32 * root.uiScale
                                iconSize: 14 * root.uiScale
                                visible: AvatarService.hasAvatar
                                normalColor: Theme.backgroundAlt
                                hoverColor: Theme.color1
                                tooltipText: "Remove"
                                onTapped: AvatarService.clearAvatar()
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── General (shared scope) ──────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                Text {
                    text: "General"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Corner Radius"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(radiusSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: radiusSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 40
                        stepSize: 1
                        uiScale: root.uiScale
                        value: root.shared.radius ?? 20
                        onMoved: root._debouncedSet("radius", Math.round(value), "shared")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Workspaces Per Monitor"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(workspacesSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: workspacesSlider
                        Layout.fillWidth: true
                        from: 1
                        to: 20
                        stepSize: 1
                        uiScale: root.uiScale

                        value: root.shared.workspacesPerMonitor ?? 10
                        onMoved: root._debouncedSet("workspacesPerMonitor", Math.round(value), "shared")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6 * root.uiScale
                    Text {
                        text: "Font"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                    }
                    TextField {
                        id: fontField
                        Layout.fillWidth: true
                        text: root.shared.fontName ?? ""
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                        selectByMouse: true

                        background: Rectangle {
                            color: Theme.backgroundAlt
                            radius: Theme.radius / 2
                            border.width: 1
                            border.color: fontField.activeFocus ? Theme.selected : Theme.borderColor

                            Behavior on border.color {
                                AnimColor {
                                    type: Anim.FastEffects
                                }
                            }
                        }

                        onEditingFinished: ThemeActions.setSetting("fontName", text, "shared")
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── Shell layout (shell scope) ───────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                Text {
                    text: "Shell Layout"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Bar Height"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(barHeightSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: barHeightSlider
                        Layout.fillWidth: true
                        from: 30
                        to: 80
                        stepSize: 1
                        uiScale: root.uiScale

                        value: root.shell.barHeight ?? 50
                        onMoved: root._debouncedSet("barHeight", Math.round(value), "shell")
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Enable Widget Borders"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                    }
                    ToggleSwitch {
                        checked: root.shell.enableWidgetBorders ?? true
                        uiScale: root.uiScale
                        onToggled: ThemeActions.setSetting("enableWidgetBorders", !checked, "shell")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    opacity: enabled ? 1.0 : 0.4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Screen Border Size"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(screenBorderSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: screenBorderSlider
                        Layout.fillWidth: true
                        from: 1
                        to: 20
                        stepSize: 1
                        uiScale: root.uiScale

                        value: root.shell.screenBorderSize ?? 10
                        onMoved: root._debouncedSet("screenBorderSize", Math.round(value), "shell")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Widget Opacity"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: widgetOpacitySlider.value.toFixed(2)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: widgetOpacitySlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        uiScale: root.uiScale
                        value: root.shell.widgetOpacity ?? 1.0
                        onMoved: root._debouncedSet("widgetOpacity", value, "shell")
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 12 * root.uiScale
            }
        }
    }
}
