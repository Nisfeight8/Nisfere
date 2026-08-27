import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "tabs"

Item {
    id: root
    property real uiScale: 1.0

    implicitWidth: 760 * uiScale
    implicitHeight: 560 * uiScale
    focus: true
    anchors.fill: parent

    Keys.onEscapePressed: ShellState.closeDashboard()

    readonly property var tabModel: [
        {
            icon: "palette",
            title: "Appearance",
            key: "appearance"
        },
        {
            icon: "layout-grid",
            title: "Hyprland",
            key: "hyprland"
        },
        {
            icon: "sliders-vertical",
            title: "Chroma",
            key: "chroma"
        },
        {
            icon: "swatch-book",
            title: "Palette",
            key: "palette"
        },
        {
            icon: "image",
            title: "Wallpapers",
            key: "wallpapers"
        },
        {
            icon: "paintbrush",
            title: "Theme Source",
            key: "source"
        },
    ]

    property int currentIndex: 0
    readonly property var currentTab: root.tabModel[root.currentIndex] ?? null
    readonly property string currentKey: root.currentTab ? root.currentTab.key : ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 10 * root.uiScale

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28 * root.uiScale

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "x"
                size: 28 * root.uiScale
                iconSize: 13 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.color1
                tooltipText: "Close"
                onTapped: ShellState.closeResumableComponent()
            }
        }

        RowLayout {
            id: bodyRow
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10 * root.uiScale

            SideMenu {
                Layout.fillHeight: true
                // Same cap-with-floor pattern as Productivity.qml/
                // AppLauncherPanel's SideMenu.
                Layout.preferredWidth: Math.max(140 * root.uiScale, Math.min(implicitWidth, bodyRow.width * 0.25))
                menuModel: root.tabModel
                currentIndex: root.currentIndex
                uiScale: root.uiScale
                onTabClicked: index => root.currentIndex = index
            }

            // ── Content area — one Loader per tab, keyed on currentKey ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "chroma"
                    visible: active
                    sourceComponent: Component {
                        ChromaTab {
                            uiScale: root.uiScale
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "palette"
                    visible: active
                    sourceComponent: Component {
                        PaletteTab {
                            uiScale: root.uiScale
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "hyprland"
                    visible: active
                    sourceComponent: Component {
                        HyprlandTab {
                            uiScale: root.uiScale
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "appearance"
                    visible: active
                    sourceComponent: Component {
                        AppearanceTab {
                            uiScale: root.uiScale
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "wallpapers"
                    visible: active
                    sourceComponent: Component {
                        WallpapersTab {
                            uiScale: root.uiScale
                        }
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "source"
                    visible: active
                    sourceComponent: Component {
                        ThemeSourceTab {
                            uiScale: root.uiScale
                        }
                    }
                }
            }
        }
    }
}
