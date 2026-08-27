import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    property string _wallpaperSearch: ""
    property bool extractDynamicColors: true

    readonly property var filteredWallpapers: {
        if (root._wallpaperSearch === "")
            return ThemeActions.wallpapers;
        const q = root._wallpaperSearch.toLowerCase();
        return ThemeActions.wallpapers.filter(w => w.name.toLowerCase().includes(q));
    }

    Component.onCompleted: ThemeActions.fetchWallpapers()

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

            // ── Mode ─────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale

                Text {
                    Layout.fillWidth: true
                    text: "Light Mode"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }
                ToggleSwitch {
                    checked: ThemeState.mode === "light"
                    uiScale: root.uiScale
                    onToggled: ThemeActions.toggleMode()
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── Extract Dynamic Colors toggle ────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * root.uiScale

                    Text {
                        text: "Extract Dynamic Colors"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "When on, picking a wallpaper below also re-extracts and applies its colors. When off, only the background image changes — your current color theme stays as-is."
                        color: Theme.foreground
                        opacity: 0.5
                        font.family: Theme.fontName
                        font.pixelSize: 11 * root.uiScale
                        wrapMode: Text.Wrap
                    }
                }
                ToggleSwitch {
                    checked: root.extractDynamicColors
                    uiScale: root.uiScale
                    onToggled: root.extractDynamicColors = !checked
                }
            }

            InfoDivider {
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
            }

            // ── Wallpaper grid ────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 10 * root.uiScale

                SearchBar {
                    Layout.fillWidth: true
                    placeholderText: "Search wallpapers..."
                    uiScale: root.uiScale
                    onTextChanged: root._wallpaperSearch = text
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.filteredWallpapers.length === 0
                    text: ThemeActions.wallpapers.length === 0 ? "No wallpapers found" : "No matches"
                    color: Theme.foreground
                    opacity: 0.4
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                }

                GridView {
                    id: wpGrid
                    Layout.fillWidth: true
                    Layout.preferredHeight: 420 * root.uiScale
                    visible: root.filteredWallpapers.length > 0
                    clip: true

                    cellWidth: 120 * root.uiScale
                    cellHeight: 100 * root.uiScale

                    model: root.filteredWallpapers

                    cacheBuffer: 200

                    ScrollBar.vertical: CustomScrollBar {
                        uiScale: root.uiScale
                    }

                    delegate: Item {
                        id: wpDelegate
                        required property var modelData
                        readonly property bool isSelected: ThemeState.sourceType === "dynamic" && ThemeState.wallpaper === modelData.path

                        width: wpGrid.cellWidth
                        height: wpGrid.cellHeight

                        ColumnLayout {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4 * root.uiScale
                            width: 110 * root.uiScale

                            Rectangle {
                                id: card
                                Layout.preferredWidth: 110 * root.uiScale
                                Layout.preferredHeight: 70 * root.uiScale
                                radius: Theme.radius
                                color: Theme.backgroundAlt
                                border.width: wpDelegate.isSelected ? 2 : 1
                                border.color: wpDelegate.isSelected ? Theme.selected : Theme.borderColor

                                Image {
                                    id: wpImage
                                    anchors.fill: parent
                                    anchors.margins: card.border.width
                                    source: "file://" + wpDelegate.modelData.path
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    visible: false
                                    sourceSize.width: 110 * root.uiScale * 2
                                    sourceSize.height: 70 * root.uiScale * 2
                                }
                                Rectangle {
                                    id: wpImageMask
                                    anchors.fill: wpImage
                                    radius: parent.radius
                                    visible: false
                                }
                                OpacityMask {
                                    anchors.fill: wpImage
                                    source: wpImage
                                    maskSource: wpImageMask
                                }

                                HoverHandler {
                                    id: wpHover
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: ThemeActions.setWallpaper(wpDelegate.modelData.path, root.extractDynamicColors, ThemeState.mode)
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Theme.selected
                                    opacity: wpHover.hovered && !wpDelegate.isSelected ? 0.12 : 0
                                    Behavior on opacity {
                                        Anim {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }
                            }
                            Text {
                                Layout.preferredWidth: 110 * root.uiScale
                                text: wpDelegate.modelData.name
                                color: wpDelegate.isSelected ? Theme.selected : Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 10 * root.uiScale
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
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
