import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    readonly property var chroma: ThemeState.chromaSettings

    readonly property var algorithms: [
        {
            key: "median_cut",
            label: "Median Cut"
        },
        {
            key: "octree",
            label: "Octree"
        },
        {
            key: "kmeans",
            label: "K-Means"
        },
        {
            key: "histogram",
            label: "Histogram"
        },
    ]

    property string _pendingKey: ""
    property var _pendingValue: null
    property Timer _debounceTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: ThemeActions.setChromaSetting(root._pendingKey, root._pendingValue)
    }
    function _debouncedSet(key, value) {
        root._pendingKey = key;
        root._pendingValue = value;
        root._debounceTimer.restart();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * root.uiScale
        spacing: 24 * root.uiScale

        // ── Info banner ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: noticeRow.implicitHeight + (20 * root.uiScale)
            radius: Theme.radius
            color: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.25)

            RowLayout {
                id: noticeRow
                anchors {
                    fill: parent
                    margins: 10 * root.uiScale
                }
                spacing: 10 * root.uiScale

                LucideIcon {
                    icon: "info"
                    size: 16 * root.uiScale
                    color: Theme.selected
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: "These settings only take visible effect when your theme is set to extract colors from a wallpaper (dynamic mode). If you're currently using a static theme, changes here are saved but won't show until you switch to a wallpaper-based theme."
                    color: Theme.foreground
                    opacity: 0.85
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                }
            }
        }

        // ── Algorithm ────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8 * root.uiScale

            Text {
                text: "Algorithm"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13 * root.uiScale
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * root.uiScale

                Repeater {
                    model: root.algorithms

                    delegate: NavTile {
                        required property var modelData
                        Layout.fillWidth: true
                        uiScale: root.uiScale
                        label: modelData.label
                        isActive: root.chroma.algorithm === modelData.key
                        onTapped: ThemeActions.setChromaSetting("algorithm", modelData.key)
                    }
                }
            }
        }

        InfoDivider {}

        // ── Saturation ───────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * root.uiScale

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Saturation"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                }
                Text {
                    text: saturationSlider.value.toFixed(2)
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }
            }
            CustomSlider {
                id: saturationSlider
                Layout.fillWidth: true
                uiScale: root.uiScale
                from: 0.0
                to: 2.5
                value: root.chroma.saturation ?? 1.3
                onMoved: root._debouncedSet("saturation", value)
            }
        }

        // ── Background saturation ──────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * root.uiScale

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Background Saturation"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                }
                Text {
                    text: bgSaturationSlider.value.toFixed(2)
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }
            }
            CustomSlider {
                id: bgSaturationSlider
                Layout.fillWidth: true
                uiScale: root.uiScale
                from: 0.0
                to: 1.0
                value: root.chroma.bg_saturation ?? 0.08
                onMoved: root._debouncedSet("bg_saturation", value)
            }
        }

        // ── Contrast ─────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * root.uiScale

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Contrast"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                }
                Text {
                    text: contrastSlider.value.toFixed(2)
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }
            }
            CustomSlider {
                id: contrastSlider
                Layout.fillWidth: true
                uiScale: root.uiScale
                from: 0.5
                to: 2.0
                value: root.chroma.contrast ?? 1.0
                onMoved: root._debouncedSet("contrast", value)
            }
        }

        InfoDivider {}

        // ── Sample resolution ────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * root.uiScale

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Sample Resolution"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                }
                Text {
                    text: Math.round(resizeSlider.value) + "px"
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                }
            }
            CustomSlider {
                id: resizeSlider
                Layout.fillWidth: true
                uiScale: root.uiScale
                from: 50
                to: 500
                stepSize: 10
                value: root.chroma.resize_to ?? 200
                onMoved: root._debouncedSet("resize_to", Math.round(value))
            }
            Text {
                Layout.fillWidth: true
                text: "Higher = more accurate sampling, slower extraction"
                color: Theme.foreground
                opacity: 0.45
                font.family: Theme.fontName
                font.pixelSize: 11 * root.uiScale
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
