import QtQuick
import QtQuick.Layouts
import qs.core

GlassCard {
    id: root

    property bool hasMore: false
    property string iconText: ""
    property bool isActive: false
    property string subtitle: "Subtitle"
    property string title: "Title"
    property real uiScale: 1.0

    signal clicked
    signal moreClicked

    Layout.fillWidth: true
    Layout.preferredHeight: 70 * uiScale

    readonly property bool isHovered: cardHover.hovered

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.isActive ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.07) : root.isHovered ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.04) : "transparent"
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }
    HoverHandler {
        id: cardHover
        cursorShape: root.isHovered ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14 * root.uiScale
        spacing: 12 * root.uiScale

        RowLayout {
            id: mainZone
            Layout.fillWidth: true
            spacing: 12 * root.uiScale

            TapHandler {
                onTapped: root.clicked()
            }

            Rectangle {
                width: 42 * root.uiScale
                height: 42 * root.uiScale
                radius: width / 2
                color: root.isActive ? Theme.selected : Theme.backgroundAlt
                border.width: root.isActive ? 0 : 1
                border.color: Theme.borderColor
                Behavior on color {
                    AnimColor {
                        type: Anim.FastEffects
                    }
                }
                Behavior on border.color {
                    AnimColor {
                        type: Anim.FastEffects
                    }
                }

                LucideIcon {
                    anchors.centerIn: parent
                    icon: root.iconText
                    size: 19 * root.uiScale
                    color: root.isActive ? Theme.background : Theme.foreground
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3 * root.uiScale

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14 * root.uiScale
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: root.isActive ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    opacity: root.isActive ? 0.85 : 0.55
                    elide: Text.ElideRight
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }
                }
            }
        }

        IconButton {
            visible: root.hasMore
            icon: "chevron-right"
            size: 30 * root.uiScale
            iconSize: 17 * root.uiScale
            normalColor: "transparent"
            onTapped: root.moreClicked()
        }
    }
}
