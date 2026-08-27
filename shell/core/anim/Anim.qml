import QtQuick
import qs.core

// Reusable NumberAnimation with named duration+easing pairs from
// AnimTokens, instead of hardcoded values scattered everywhere.
// Usage: Anim { type: Anim.DefaultSpatial }
NumberAnimation {
    id: root

    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects,
        // Value-reveal animations (gauges, charts, sparklines) — see
        // AnimTokens.durationDataReveal for why this isn't folded
        // into Spatial or Effects.
        DataReveal,
        // Quick position slides (toggle switch knobs, etc.) — spatial
        // in nature but needs to feel snappier than FastSpatial/350ms.
        FastToggle
    }

    property int type: Anim.DefaultSpatial

    duration: {
        switch (type) {
        case Anim.StandardSmall:
        case Anim.EmphasizedSmall:
            return AnimTokens.durationSmall;
        case Anim.Standard:
        case Anim.Emphasized:
            return AnimTokens.durationNormal;
        case Anim.StandardLarge:
        case Anim.EmphasizedLarge:
            return AnimTokens.durationLarge;
        case Anim.StandardExtraLarge:
        case Anim.EmphasizedExtraLarge:
            return AnimTokens.durationExtraLarge;
        case Anim.FastSpatial:
            return AnimTokens.durationFastSpatial;
        case Anim.DefaultSpatial:
            return AnimTokens.durationDefaultSpatial;
        case Anim.SlowSpatial:
            return AnimTokens.durationSlowSpatial;
        case Anim.FastEffects:
            return AnimTokens.durationFastEffects;
        case Anim.DefaultEffects:
            return AnimTokens.durationDefaultEffects;
        case Anim.SlowEffects:
            return AnimTokens.durationSlowEffects;
        case Anim.DataReveal:
            return AnimTokens.durationDataReveal;
        case Anim.FastToggle:
            return AnimTokens.durationFastToggle;
        default:
            return AnimTokens.durationNormal;
        }
    }

    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        switch (type) {
        case Anim.FastSpatial:
            return AnimTokens.curveFastSpatial;
        case Anim.DefaultSpatial:
            return AnimTokens.curveDefaultSpatial;
        case Anim.SlowSpatial:
            return AnimTokens.curveSlowSpatial;
        case Anim.FastEffects:
            return AnimTokens.curveFastEffects;
        case Anim.DefaultEffects:
            return AnimTokens.curveDefaultEffects;
        case Anim.SlowEffects:
            return AnimTokens.curveSlowEffects;
        case Anim.DataReveal:
            return AnimTokens.curveStandardDecel;
        case Anim.FastToggle:
            return AnimTokens.curveStandardDecel;
        case Anim.EmphasizedSmall:
        case Anim.Emphasized:
        case Anim.EmphasizedLarge:
        case Anim.EmphasizedExtraLarge:
            return AnimTokens.curveEmphasized;
        default:
            return AnimTokens.curveStandard;
        }
    }
}
