import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root
    property var tabModel: []
    property int currentIndex: 0
    property real uiScale: 1.0

    signal tabClicked(int tabIndex)

    spacing: 10 * root.uiScale

    Repeater {
        model: root.tabModel

        delegate: Item {
            property bool isHovered: tabHover.hovered
            property bool isSelected: root.currentIndex === index

            Layout.fillWidth: true
            implicitHeight: content.implicitHeight + (12 * root.uiScale)

            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: 8 * root.uiScale

                LucideIcon {
                    icon: modelData.icon
                    size: 18 * root.uiScale
                    color: isSelected ? Theme.selected : Theme.foreground
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                }

                Text {
                    text: modelData.title
                    color: isSelected ? Theme.selected : Theme.foreground
                    font.bold: isSelected
                    font.family: Theme.fontName
                    font.pixelSize: 14 * root.uiScale
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.selected
                height: 3 * root.uiScale
                radius: 2 * root.uiScale
                opacity: isSelected ? 1 : 0
                width: isSelected ? parent.width * 0.6 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
            }

            HoverHandler {
                id: tabHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: root.tabClicked(index)
            }
        }
    }
}
