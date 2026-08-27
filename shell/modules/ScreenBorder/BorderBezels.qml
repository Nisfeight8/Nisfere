import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.core

// Visual border decoration (the 4 bezel lines + rounded corners) and
// their hover detection. Deliberately knows NOTHING about drawers —
// just exposes each edge's hover state as a readonly alias, so
// ScreenBorder.qml decides what opening each edge should trigger,
// keeping this component reusable/decoupled.
Item {
    id: root

    property real bezelSize: Theme.screenBorderSize
    property color borderLineColor: Theme.borderColor
    property int cornerRadius: Theme.radius
    property real topBarHeight: Theme.scaledBarHeight(QsWindow.window?.screen)

    readonly property alias topHovered: topBorderHover.hovered
    readonly property alias bottomHovered: bottomBorderHover.hovered
    readonly property alias leftHovered: leftBorderHover.hovered
    readonly property alias rightHovered: rightBorderHover.hovered

    // Exposed so ScreenBorder.qml's mask can reference these items
    // directly (Region { item: borderBezels.topBorderItem }, etc.)
    readonly property alias topBorderItem: topBorderLine
    readonly property alias bottomBorderItem: bottomBorderLine
    readonly property alias leftBorderItem: leftBorderLine
    readonly property alias rightBorderItem: rightBorderLine

    anchors.fill: parent

    // --- Top Border ---
    Rectangle {
        id: topBorderLine

        anchors.left: parent.left
        anchors.leftMargin: root.bezelSize + Theme.radius
        anchors.right: parent.right
        anchors.rightMargin: root.bezelSize + Theme.radius
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        color: root.borderLineColor
        height: Theme.widgetBorderWidth

        HoverHandler {
            id: topBorderHover
        }
    }

    // --- Bottom Bezel ---
    Rectangle {
        id: bottomBorderLine

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: Theme.background
        height: root.bezelSize

        HoverHandler {
            id: bottomBorderHover
        }

        Rectangle {
            anchors.bottom: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.radius
            anchors.rightMargin: Theme.radius
            color: root.borderLineColor
            height: Theme.widgetBorderWidth
        }
    }

    // --- Left Bezel ---
    Rectangle {
        id: leftBorderLine

        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        color: Theme.background
        width: root.bezelSize

        HoverHandler {
            id: leftBorderHover
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.right
            anchors.top: parent.top
            anchors.bottomMargin: Theme.radius
            anchors.topMargin: Theme.radius
            color: root.borderLineColor
            width: Theme.widgetBorderWidth
        }
    }

    // --- Right Bezel ---
    Rectangle {
        id: rightBorderLine

        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        color: Theme.background
        width: root.bezelSize

        HoverHandler {
            id: rightBorderHover
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.radius
            anchors.topMargin: Theme.radius
            anchors.right: parent.left
            anchors.top: parent.top
            color: root.borderLineColor
            width: Theme.widgetBorderWidth
        }
    }

    ScreenCorner {
        anchors.left: parent.left
        anchors.leftMargin: root.bezelSize
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
    }
    ScreenCorner {
        anchors.right: parent.right
        anchors.rightMargin: root.bezelSize
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        rotation: 90
    }
    ScreenCorner {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        anchors.right: parent.right
        anchors.rightMargin: root.bezelSize
        rotation: 180
    }
    ScreenCorner {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        anchors.left: parent.left
        anchors.leftMargin: root.bezelSize
        rotation: 270
    }

    component ScreenCorner: Shape {
        property real bw: Theme.widgetBorderWidth
        property real offset: bw / 2.0
        property int r: root.cornerRadius

        antialiasing: true
        height: r
        preferredRendererType: Shape.CurveRenderer
        width: r

        ShapePath {
            fillColor: Theme.background
            startX: 0
            startY: 0
            strokeColor: "transparent"

            PathLine {
                x: r
                y: 0
            }
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: r
                radiusY: r
                x: 0
                y: r
            }
            PathLine {
                x: 0
                y: 0
            }
        }
        ShapePath {
            fillColor: "transparent"
            startX: r
            startY: offset
            strokeColor: root.borderLineColor
            strokeWidth: bw

            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: r - offset
                radiusY: r - offset
                x: offset
                y: r
            }
        }
    }
}
