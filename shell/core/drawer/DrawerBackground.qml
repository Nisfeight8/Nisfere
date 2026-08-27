import QtQuick
import qs.core

// The drawer's visible background shape. Switches between a straight
// panel edge or a rounded corner shape, and animates the border color
// in/out with the open state. Purely visual — no geometry math here.
Item {
    id: root

    property int edge: Qt.LeftEdge
    property bool cornerMode: false
    property bool sidePanelMode: false
    property int cornerSecondaryEdge: Qt.TopEdge
    property bool opened: false
    property color bgColor: Theme.background

    readonly property color _borderColor: opened ? Theme.borderColor : "transparent"

    Loader {
        anchors.fill: parent
        sourceComponent: {
            if (root.cornerMode) return cornerShapeComp;
            if (root.sidePanelMode) return sidePanelShapeComp;
            return panelShapeComp;
        }
    }

    Component {
        id: panelShapeComp
        PanelShape {
            anchors.fill: parent
            bgColor: root.bgColor
            borderColor: root._borderColor
            edge: root.edge
            Behavior on borderColor {
                AnimColor {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
    Component {
        id: sidePanelShapeComp
        SidePanelShape {
            anchors.fill: parent
            bgColor: root.bgColor
            borderColor: root._borderColor
            edge: root.edge
            Behavior on borderColor {
                AnimColor {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
    Component {
        id: cornerShapeComp
        CornerShape {
            anchors.fill: parent
            bgColor: root.bgColor
            borderColor: root._borderColor
            edge: root.edge
            cornerAtTop: root.cornerSecondaryEdge === Qt.TopEdge
            Behavior on borderColor {
                AnimColor {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
