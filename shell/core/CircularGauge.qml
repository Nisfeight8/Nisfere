import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.core

Item {
    id: root

    property real animatedValue: 0.0
    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real circleRadius: (effectiveSize / 2) - (dynamicStrokeWidth / 2)
    readonly property real dynamicStrokeWidth: Math.max(4, effectiveSize * 0.08)
    readonly property real effectiveSize: Math.min(width, height)
    property string mainText: "0"
    property color progressColor: Theme.selected
    property string sideTextSubtitle: "Usage"
    property string sideTextTitle: "0%"
    // Set false to hide the corner label entirely (e.g. for timers/
    // countdowns where a "usage %" style side label doesn't make sense).
    property bool showSideText: true
    property string subText: "Metric"
    property color trackColor: Theme.backgroundAlt
    property real value: 0.0

    implicitHeight: 120
    implicitWidth: 120

    Behavior on animatedValue {
        id: valueBehavior
        Anim {
            type: Anim.DataReveal
        }
    }

    onValueChanged: animatedValue = value

    Component.onCompleted: {
        // Skip the fill-from-zero reveal on initial mount — only
        // animate genuine value CHANGES afterwards. Otherwise every
        // time this gauge gets lazily re-loaded (e.g. inside a panel
        // that opens/closes via a Loader), it replays the same "count
        // up from zero" animation even when the value hasn't changed
        // at all since the last time it was visible.
        valueBehavior.enabled = false;
        animatedValue = value;
        valueBehavior.enabled = true;
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.dynamicStrokeWidth

            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.circleRadius
                radiusY: root.circleRadius
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeColor: root.progressColor
            strokeWidth: root.dynamicStrokeWidth

            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.circleRadius
                radiusY: root.circleRadius
                startAngle: 135
                sweepAngle: root.animatedValue * 360
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: -root.effectiveSize * 0.02

        Text {
            Layout.alignment: Qt.AlignHCenter
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: root.effectiveSize * 0.22
            text: root.mainText
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            color: Theme.foreground
            font.pixelSize: root.effectiveSize * 0.09
            opacity: 0.6
            text: root.subText
        }
    }

    ColumnLayout {
        visible: root.showSideText
        spacing: -2
        x: root.centerX + (root.circleRadius * 0.707)
        y: root.centerY + (root.circleRadius * 0.707) - (height / 2)

        Text {
            Layout.alignment: Qt.AlignHCenter
            color: Theme.foreground
            font.bold: true
            font.pixelSize: root.effectiveSize * 0.10
            text: root.sideTextTitle
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            color: Theme.foreground
            font.pixelSize: root.effectiveSize * 0.08
            opacity: 0.6
            text: root.sideTextSubtitle
        }
    }
}
