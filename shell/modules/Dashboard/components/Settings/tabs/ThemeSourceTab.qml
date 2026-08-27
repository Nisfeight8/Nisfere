import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    property string _themeSearch: ""

    readonly property var filteredThemes: {
        if (root._themeSearch === "")
            return ThemeActions.themes;
        const q = root._themeSearch.toLowerCase();
        return ThemeActions.themes.filter(t => t.name.toLowerCase().includes(q));
    }

    Component.onCompleted: ThemeActions.fetchThemes()

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

            // ── Static Themes ────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                spacing: 10 * root.uiScale

                Text {
                    text: "Static Themes"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }

                SearchBar {
                    Layout.fillWidth: true
                    placeholderText: "Search themes..."
                    uiScale: root.uiScale
                    onTextChanged: root._themeSearch = text
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.filteredThemes.length === 0
                    text: ThemeActions.themes.length === 0 ? "No themes found" : "No matches"
                    color: Theme.foreground
                    opacity: 0.4
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10 * root.uiScale

                    Repeater {
                        model: root.filteredThemes

                        delegate: ColumnLayout {
                            required property var modelData
                            readonly property bool isSelected: ThemeState.sourceType === "static" && ThemeState.sourceName === modelData.name

                            spacing: 4 * root.uiScale
                            width: 110 * root.uiScale

                            Rectangle {
                                id: swatchBox
                                Layout.preferredWidth: 110 * root.uiScale
                                Layout.preferredHeight: 70 * root.uiScale
                                radius: Theme.radius
                                color: modelData.colors.background ?? Theme.backgroundAlt
                                border.width: isSelected ? 2 : 1
                                border.color: isSelected ? Theme.selected : Theme.borderColor
                                clip: true

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 3 * root.uiScale

                                    Repeater {
                                        model: [1, 2, 3, 4, 5, 6]
                                        delegate: Rectangle {
                                            required property int modelData
                                            width: 12 * root.uiScale
                                            height: 12 * root.uiScale
                                            radius: 2 * root.uiScale
                                            color: swatchBox.parent.modelData.colors["color" + modelData] ?? "#888888"
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: themeHover
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: ThemeActions.setColors(modelData.name, ThemeState.mode)
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.selected
                                    opacity: themeHover.hovered && !isSelected ? 0.12 : 0
                                    radius: Theme.radius
                                    Behavior on opacity {
                                        Anim {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }
                            }
                            Text {
                                Layout.preferredWidth: 110 * root.uiScale
                                text: modelData.name
                                color: isSelected ? Theme.selected : Theme.foreground
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
