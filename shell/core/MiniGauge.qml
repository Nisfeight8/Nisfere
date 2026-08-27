import QtQuick
import QtQuick.Shapes
import qs.core

// Tiny percentage ring, no text inside — for compact bar widgets where
// a plain "icon + %" felt too ambiguous. Pair it with a Text label next
// to it for the exact value; the ring itself makes it instantly obvious
// this is a progress/percentage indicator at a glance.
// Usage: MiniGauge { width: 18; height: 18; value: 0.45 }
Item {
    id: root

    property real value: 0.0          // 0.0–1.0
    property color progressColor: Theme.selected
    property color trackColor: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
    property real strokeWidth: 2.5

    // Consumers (e.g. SystemStatsWidget) swap progressColor based on a
    // threshold (CPU > 80% turns red) — without this, that swap would
    // snap instantly instead of matching the rest of the shell's
    // smooth color transitions.
    Behavior on progressColor {
        AnimColor {
            type: Anim.FastEffects
        }
    }

    property real animatedValue: 0.0
    onValueChanged: animatedValue = value
    Behavior on animatedValue {
        id: valueBehavior
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Component.onCompleted: {
        // Same reasoning as CircularGauge: skip the fill-from-zero
        // reveal on initial mount, only animate genuine value changes
        // afterwards — otherwise every time this gets lazily re-loaded
        // (e.g. inside a panel that opens/closes via a Loader), it
        // replays the same animation even if the value hasn't changed.
        valueBehavior.enabled = false;
        animatedValue = value;
        valueBehavior.enabled = true;
    }

    readonly property real _radius: (Math.min(width, height) - strokeWidth) / 2

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.strokeWidth
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeColor: root.progressColor
            strokeWidth: root.strokeWidth
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: 135
                sweepAngle: root.animatedValue * 360
            }
        }
    }
}
