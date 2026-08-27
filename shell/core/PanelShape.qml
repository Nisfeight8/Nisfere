import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color bgColor: Theme.background
    property color borderColor: Theme.borderColor
    property int edge: Qt.TopEdge
    property int invRadius: 16
    readonly property bool isHorizontal: edge === Qt.LeftEdge || edge === Qt.RightEdge
    property int normalRadius: Theme.radius
    property int bottomOffset: invRadius / 1.2

    Shape {
        id: theShape

        height: isHorizontal ? root.width : root.height
        layer.enabled: true
        rotation: {
            switch (root.edge) {
            case Qt.LeftEdge:
                return -90;
            case Qt.RightEdge:
                return 90;
            case Qt.BottomEdge:
                return 180;
            default:
                return 0;
            }
        }
        transformOrigin: Item.TopLeft
        width: isHorizontal ? root.height : root.width
        x: {
            switch (root.edge) {
            case Qt.RightEdge:
                return root.width;
            case Qt.BottomEdge:
                return root.width;
            default:
                return 0;
            }
        }
        y: {
            switch (root.edge) {
            case Qt.LeftEdge:
                return root.height;
            case Qt.BottomEdge:
                return root.height;
            default:
                return 0;
            }
        }

        ShapePath {
            fillColor: root.bgColor
            startX: 0
            startY: 0
            strokeColor: "transparent"

            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: root.invRadius
                y: root.invRadius
            }
            PathLine {
                x: root.invRadius
                y: theShape.height - root.normalRadius - root.bottomOffset
            }
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.normalRadius
                radiusY: root.normalRadius
                x: root.invRadius + root.normalRadius
                y: theShape.height - root.bottomOffset
            }
            PathLine {
                x: theShape.width - root.invRadius - root.normalRadius
                y: theShape.height - root.bottomOffset
            }
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.normalRadius
                radiusY: root.normalRadius
                x: theShape.width - root.invRadius
                y: theShape.height - root.normalRadius - root.bottomOffset
            }
            PathLine {
                x: theShape.width - root.invRadius
                y: root.invRadius
            }
            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: theShape.width
                y: 0
            }
            PathLine {
                x: 0
                y: 0
            }
        }

        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
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
                y: theShape.height - root.normalRadius - root.bottomOffset
            }
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.normalRadius
                radiusY: root.normalRadius
                x: root.invRadius + root.normalRadius
                y: theShape.height - root.bottomOffset
            }
            PathLine {
                x: theShape.width - root.invRadius - root.normalRadius
                y: theShape.height - root.bottomOffset
            }
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.normalRadius
                radiusY: root.normalRadius
                x: theShape.width - root.invRadius
                y: theShape.height - root.normalRadius - root.bottomOffset
            }
            PathLine {
                x: theShape.width - root.invRadius
                y: root.invRadius
            }
            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: theShape.width
                y: 0
            }
        }
    }
}
