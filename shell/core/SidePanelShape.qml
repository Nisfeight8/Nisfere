import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color bgColor: Theme.background
    property color borderColor: Theme.borderColor
    property int edge: Qt.RightEdge
    property int invRadius: 16
    
    property int normalRadius: Theme.radius

    property int bottomOffset: 0
    property bool cornerAtTop: true

    Shape {
        id: theShape
        anchors.fill: parent
        layer.enabled: true

        transformOrigin: Item.Center
        transform: Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: root.edge === Qt.LeftEdge ? -1 : 1
            yScale: root.cornerAtTop ? 1 : -1
        }

        // ── FILL ──────────────────────────────────────────────────────
        ShapePath {
            fillColor: root.bgColor
            startX: 0
            startY: 0
            strokeColor: "transparent"

            // Top left
            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: root.invRadius
                y: root.invRadius
            }
            
            PathLine {
                x: root.invRadius
                y: theShape.height - root.invRadius - root.bottomOffset
            }
            
            // Bottom left
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: 0
                y: theShape.height - root.bottomOffset
            }
            
            PathLine {
                x: theShape.width
                y: theShape.height - root.bottomOffset
            }
            
            PathLine {
                x: theShape.width
                y: 0
            }
            
            PathLine {
                x: 0
                y: 0
            }
        }

        // ── BORDER ────────────────────────────────────────────────────
        ShapePath {
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            startX: 0
            startY: 0
            strokeColor: root.borderColor
            strokeWidth: Theme.widgetBorderWidth

            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: root.invRadius
                y: root.invRadius
            }
            PathLine {
                x: root.invRadius
                y: theShape.height - root.invRadius - root.bottomOffset
            }
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: 0
                y: theShape.height - root.bottomOffset
            }
            
        }
    }
}