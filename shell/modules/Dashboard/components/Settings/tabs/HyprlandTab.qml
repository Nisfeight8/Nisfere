import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    readonly property var hypr: ThemeState.hyprland

    property string _pendingKey: ""
    property var _pendingValue: null
    property Timer _debounceTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: ThemeActions.setSetting(root._pendingKey, root._pendingValue, "hyprland")
    }
    function _debouncedSet(key, value) {
        root._pendingKey = key;
        root._pendingValue = value;
        root._debounceTimer.restart();
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

            // ── Gaps ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                Text {
                    text: "Gaps"
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
                            text: "Workspace Gaps"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(workspaceGapsSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: workspaceGapsSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 0
                        to: 100
                        stepSize: 2
                        value: root.hypr.workspaceGaps ?? 20
                        onMoved: root._debouncedSet("workspaceGaps", Math.round(value))
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Window Gaps (Inner)"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(gapsInSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: gapsInSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 0
                        to: 30
                        stepSize: 1
                        value: root.hypr.windowGapsIn ?? 6
                        onMoved: root._debouncedSet("windowGapsIn", Math.round(value))
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Window Gaps (Outer)"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(gapsOutSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: gapsOutSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 0
                        to: 50
                        stepSize: 2
                        value: root.hypr.windowGapsOut ?? 20
                        onMoved: root._debouncedSet("windowGapsOut", Math.round(value))
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── Borders ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 4 * root.uiScale

                Text {
                    text: "Borders"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Border Size"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                    }
                    Text {
                        text: Math.round(borderSizeSlider.value) + "px"
                        color: Theme.selected
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                        font.bold: true
                    }
                }
                CustomSlider {
                    id: borderSizeSlider
                    Layout.fillWidth: true
                    uiScale: root.uiScale
                    from: 0
                    to: 10
                    stepSize: 1
                    value: root.hypr.windowBorderSize ?? 2
                    onMoved: root._debouncedSet("windowBorderSize", Math.round(value))
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── Opacity ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                Text {
                    text: "Opacity"
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
                            text: "Active Window"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: opacityActiveSlider.value.toFixed(2)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: opacityActiveSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 0.0
                        to: 1.0
                        value: root.hypr.opacityActive ?? 0.95
                        onMoved: root._debouncedSet("opacityActive", value)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Inactive Window"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: opacityInactiveSlider.value.toFixed(2)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: opacityInactiveSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 0.0
                        to: 1.0
                        value: root.hypr.opacityInactive ?? 0.85
                        onMoved: root._debouncedSet("opacityInactive", value)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Fullscreen Window"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: opacityFullscreenSlider.value.toFixed(2)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: opacityFullscreenSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 0.0
                        to: 1.0
                        value: root.hypr.opacityFullscreen ?? 1.0
                        onMoved: root._debouncedSet("opacityFullscreen", value)
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── Blur ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Blur"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                        font.bold: true
                    }
                    ToggleSwitch {
                        checked: root.hypr.blurEnabled ?? true
                        uiScale: root.uiScale
                        onToggled: ThemeActions.setSetting("blurEnabled", !checked, "hyprland")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    enabled: root.hypr.blurEnabled ?? true
                    opacity: enabled ? 1.0 : 0.4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Blur Size"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(blurSizeSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: blurSizeSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 0
                        to: 20
                        stepSize: 1
                        value: root.hypr.blurSize ?? 8
                        onMoved: root._debouncedSet("blurSize", Math.round(value))
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Blur Passes"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(blurPassesSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: blurPassesSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 1
                        to: 5
                        stepSize: 1
                        value: root.hypr.blurPasses ?? 3
                        onMoved: root._debouncedSet("blurPasses", Math.round(value))
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Blur Popups"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        ToggleSwitch {
                            checked: root.hypr.blurPopups ?? true
                            uiScale: root.uiScale
                            onToggled: ThemeActions.setSetting("blurPopups", !checked, "hyprland")
                        }
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── Shadow ───────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Shadow"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                        font.bold: true
                    }
                    ToggleSwitch {
                        checked: root.hypr.shadowEnabled ?? true
                        uiScale: root.uiScale
                        onToggled: ThemeActions.setSetting("shadowEnabled", !checked, "hyprland")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    enabled: root.hypr.shadowEnabled ?? true
                    opacity: enabled ? 1.0 : 0.4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Shadow Range"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(shadowRangeSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: shadowRangeSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 0
                        to: 50
                        stepSize: 1
                        value: root.hypr.shadowRange ?? 15
                        onMoved: root._debouncedSet("shadowRange", Math.round(value))
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Shadow Render Power"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(shadowPowerSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: shadowPowerSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 1
                        to: 4
                        stepSize: 1
                        value: root.hypr.shadowRenderPower ?? 4
                        onMoved: root._debouncedSet("shadowRenderPower", Math.round(value))
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── Cursor ───────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                Text {
                    text: "Cursor"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }

                InfoRow {
                    Layout.fillWidth: true
                    label: "Cursor Theme"
                    value: root.hypr.cursorTheme ?? "—"
                    uiScale: root.uiScale
                }
                Text {
                    Layout.fillWidth: true
                    text: "Auto-selected for contrast with the current mode — not directly editable."
                    color: Theme.foreground
                    opacity: 0.45
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    wrapMode: Text.Wrap
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * root.uiScale
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Cursor Size"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                        }
                        Text {
                            text: Math.round(cursorSizeSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: cursorSizeSlider
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        from: 16
                        to: 48
                        stepSize: 4
                        value: root.hypr.cursorSize ?? 24
                        onMoved: root._debouncedSet("cursorSize", Math.round(value))
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
