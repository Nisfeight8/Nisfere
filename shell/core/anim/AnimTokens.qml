pragma Singleton
import QtQuick

// Material 3 motion tokens — durations and easing curves.
// These are the standard M3 motion-system constants (publicly documented
// spec numbers, not creative content) — reimplemented here as our own
// singleton so `Anim`/`AnimColor` can reference them.
QtObject {
    id: root

    // ── Durations (ms) ───────────────────────────────────────────
    readonly property int durationSmall: 200
    readonly property int durationNormal: 400
    readonly property int durationLarge: 600
    readonly property int durationExtraLarge: 1000

    readonly property int durationFastSpatial: 350
    readonly property int durationDefaultSpatial: 500
    readonly property int durationSlowSpatial: 650

    // Quick position slides that need to feel more immediate than the
    // general Spatial family (which starts at 350ms) — e.g. a toggle
    // switch's knob. Reuses curveStandardDecel below rather than a new
    // curve: same pure-decelerate character, just faster.
    readonly property int durationFastToggle: 200

    readonly property int durationFastEffects: 150
    readonly property int durationDefaultEffects: 200
    readonly property int durationSlowEffects: 300

    // Value-reveal animations (gauges, charts, sparklines filling in
    // to a new value) — not a spatial move, not a pure opacity/color
    // effect, so it gets its own bucket rather than being squeezed
    // into either. First introduced for CircularGauge's animatedValue.
    readonly property int durationDataReveal: 800

    // ── Curves — control points for Easing.BezierSpline ──────────
    // Single-segment curves: [c1x, c1y, c2x, c2y, endx, endy]
    // Multi-segment (emphasized): two segments concatenated (12 values)
    readonly property var curveStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property var curveStandardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property var curveStandardDecel: [0, 0, 0, 1, 1, 1]

    readonly property var curveEmphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    readonly property var curveEmphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var curveEmphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]

    readonly property var curveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var curveDefaultSpatial: [0.38, 1, 0.22, 1, 1, 1]
    readonly property var curveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]

    readonly property var curveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property var curveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var curveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
}
