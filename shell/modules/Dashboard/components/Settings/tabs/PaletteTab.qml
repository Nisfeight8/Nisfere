import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    readonly property var shared: ThemeState.shared

    readonly property var specialColors: [
        {
            key: "background",
            label: "Background"
        },
        {
            key: "foreground",
            label: "Foreground"
        },
        {
            key: "backgroundAlt",
            label: "Background Alt"
        },
        {
            key: "foregroundAlt",
            label: "Foreground Alt"
        },
        {
            key: "accent",
            label: "Accent"
        },
        {
            key: "cursor",
            label: "Cursor"
        },
        {
            key: "borderColor",
            label: "Border"
        },
    ]

    readonly property string _sourceLabel: ThemeState.sourceType === "static" ? "Static Theme" : "Dynamic (Wallpaper)"
    readonly property string _sourceValue: ThemeState.sourceType === "static" ? (ThemeState.sourceName || "—") : (ThemeState.wallpaper ? ThemeState.wallpaper.split("/").pop() : "—")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * root.uiScale
        spacing: 20 * root.uiScale

        // ── Current source info ──────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6 * root.uiScale

            InfoRow {
                Layout.fillWidth: true
                uiScale: root.uiScale
                label: "Source"
                value: root._sourceLabel
                valueColor: Theme.selected
            }
            InfoRow {
                Layout.fillWidth: true
                uiScale: root.uiScale
                label: ThemeState.sourceType === "static" ? "Theme" : "Wallpaper"
                value: root._sourceValue
            }
            InfoRow {
                Layout.fillWidth: true
                uiScale: root.uiScale
                label: "Mode"
                value: ThemeState.mode === "dark" ? "Dark" : "Light"
            }
        }

        InfoDivider {}

        // ── 16-color palette ──────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8 * root.uiScale

            Text {
                text: "Palette"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13 * root.uiScale
                font.bold: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 8
                rowSpacing: 12 * root.uiScale
                columnSpacing: 8 * root.uiScale

                Repeater {
                    model: 16

                    delegate: ColumnLayout {
                        required property int index
                        readonly property string hex: root.shared["color" + index] ?? "#000000"

                        spacing: 4 * root.uiScale

                        Rectangle {
                            Layout.preferredWidth: 40 * root.uiScale
                            Layout.preferredHeight: 40 * root.uiScale
                            Layout.alignment: Qt.AlignHCenter
                            radius: Theme.radius / 2
                            color: parent.hex
                            border.width: 1
                            border.color: Theme.borderColor
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: index
                            color: Theme.foreground
                            opacity: 0.6
                            font.family: Theme.fontName
                            font.pixelSize: 10 * root.uiScale
                        }
                    }
                }
            }
        }

        InfoDivider {}

        // ── Special colors ────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8 * root.uiScale

            Text {
                text: "Special"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13 * root.uiScale
                font.bold: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 14 * root.uiScale
                columnSpacing: 12 * root.uiScale

                Repeater {
                    model: root.specialColors

                    delegate: ColumnLayout {
                        required property var modelData
                        readonly property string hex: root.shared[modelData.key] ?? "#000000"

                        spacing: 4 * root.uiScale

                        Rectangle {
                            Layout.preferredWidth: 48 * root.uiScale
                            Layout.preferredHeight: 48 * root.uiScale
                            Layout.alignment: Qt.AlignHCenter
                            radius: Theme.radius / 2
                            color: parent.hex
                            border.width: 1
                            border.color: Theme.borderColor
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            color: Theme.foreground
                            opacity: 0.75
                            font.family: Theme.fontName
                            font.pixelSize: 10 * root.uiScale
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: hex
                            color: Theme.foreground
                            opacity: 0.4
                            font.family: Theme.fontName
                            font.pixelSize: 9 * root.uiScale
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
