import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root
    property real uiScale: 1.0

    required property var result
    property bool isSelected: false
    readonly property bool isHovered: rowHover.hovered
    readonly property var actions: root.result.actions || []
    readonly property var swatches: root.result.swatches || []
    readonly property bool hasThumbnail: !!root.result.thumbnail

    readonly property string _thumbnailSource: {
        if (!root.hasThumbnail)
            return "";
        const t = root.result.thumbnail;
        return t.indexOf("://") !== -1 ? t : "file://" + t;
    }

    signal activated

    width: ListView.view ? ListView.view.width : implicitWidth
    // Must stay in sync with ResultsListView.rowHeight — see that
    // file's own comment on this. Both use `56 * uiScale`.
    height: 56 * root.uiScale

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.selected
        opacity: root.isSelected ? 0.18 : (root.isHovered ? 0.08 : 0)
        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14 * root.uiScale
            rightMargin: 14 * root.uiScale
        }
        spacing: 12 * root.uiScale

        Item {
            id: activatableArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 12 * root.uiScale

                LucideIcon {
                    visible: !root.hasThumbnail
                    icon: root.result.icon || "circle"
                    size: 20 * root.uiScale
                    color: root.isSelected ? Theme.selected : Theme.foreground
                    opacity: root.isSelected ? 1.0 : 0.75
                }

                // ── Thumbnail preview (wallpapers, app icons, etc.) ──
                Item {
                    visible: root.hasThumbnail
                    Layout.preferredWidth: 40 * root.uiScale
                    Layout.preferredHeight: 40 * root.uiScale

                    Image {
                        anchors.fill: parent
                        source: root._thumbnailSource
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 40 * root.uiScale * 2
                        sourceSize.height: 40 * root.uiScale * 2
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * root.uiScale

                    Text {
                        Layout.fillWidth: true
                        text: root.result.title
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 14 * root.uiScale
                        font.bold: root.isSelected
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !!root.result.subtitle
                        text: root.result.subtitle || ""
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 11 * root.uiScale
                        opacity: 0.45
                        elide: Text.ElideRight
                    }
                }

                Row {
                    visible: root.swatches.length > 0
                    spacing: 4 * root.uiScale
                    Repeater {
                        model: root.swatches
                        delegate: Rectangle {
                            required property var modelData
                            width: 10 * root.uiScale
                            height: 10 * root.uiScale
                            radius: width / 2
                            color: modelData
                            border.width: 1
                            border.color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.4)
                        }
                    }
                }

                Text {
                    visible: !!root.result.confirmed
                    text: "✓"
                    color: Theme.selected
                    font.pixelSize: 16 * root.uiScale
                    font.bold: true
                }
            }

            HoverHandler {
                id: rowHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: root.activated()
            }
        }

        Row {
            visible: root.actions.length > 0
            spacing: 4 * root.uiScale
            Repeater {
                model: root.actions
                delegate: IconButton {
                    required property var modelData
                    size: 28 * root.uiScale
                    iconSize: 14 * root.uiScale
                    icon: modelData.icon
                    normalColor: "transparent"
                    hoverColor: Theme.selected
                    onTapped: modelData.trigger()
                }
            }
        }
    }
}
