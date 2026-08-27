import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

Item {
    id: root

    property var menuModel: []
    property int currentIndex: 0
    property real uiScale: 1.0
    signal tabClicked(int tabIndex)

    // Default preferred width — callsites in a width-constrained
    // container (e.g. Productivity.qml on a small screen) should
    // override this via Layout.preferredWidth with a capped formula
    // instead of relying on this raw default, since 220 alone doesn't
    // know anything about how much total space its container actually
    // has.
    implicitWidth: 220 * uiScale

    ListView {
        anchors.fill: parent
        model: root.menuModel
        spacing: 5 * root.uiScale
        clip: true
        interactive: true
        ScrollBar.vertical: CustomScrollBar {
            uiScale: root.uiScale
            
        }
        delegate: Item {
            width: ListView.view.width
            height: 45 * root.uiScale

            property bool isHovered: itemHover.hovered
            property bool isSelected: root.currentIndex === index

            Rectangle {
                anchors.fill: parent
                color: Theme.foreground
                opacity: isHovered && !isSelected ? 0.05 : 0
                radius: Theme.radius
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20 * root.uiScale
                spacing: 12 * root.uiScale

                LucideIcon {
                    icon: modelData.icon
                    size: 18 * root.uiScale
                    color: isSelected ? Theme.selected : Theme.foreground
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)

                    Behavior on color {
                        AnimColor {
                            type: Anim.DefaultEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: isSelected ? Theme.selected : Theme.foreground
                    font.bold: isSelected
                    font.family: Theme.fontName
                    font.pixelSize: 14 * root.uiScale
                    elide: Text.ElideRight
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)

                    Behavior on color {
                        AnimColor {
                            type: Anim.DefaultEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 4 * root.uiScale
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.selected
                width: 3 * root.uiScale
                radius: 2 * root.uiScale
                opacity: isSelected ? 1 : 0
                height: isSelected ? parent.height * 0.5 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
            }

            HoverHandler {
                id: itemHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: root.tabClicked(index)
            }
        }
    }
}
