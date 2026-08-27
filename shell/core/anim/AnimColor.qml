import QtQuick
import qs.core

// ColorAnimation counterpart to Anim — same named types/durations/curves,
// for use in `Behavior on someColor { AnimColor { type: Anim.DefaultEffects } }`.
// NumberAnimation can't drive color properties, hence this sibling type;
// it shares Anim's Type enum (referenced as Anim.XXX) to keep one naming
// scheme across both.
ColorAnimation {
    id: root

    property int type: Anim.DefaultEffects

    duration: {
        switch (type) {
        case Anim.StandardSmall:
        case Anim.EmphasizedSmall:      return AnimTokens.durationSmall;
        case Anim.Standard:
        case Anim.Emphasized:           return AnimTokens.durationNormal;
        case Anim.StandardLarge:
        case Anim.EmphasizedLarge:      return AnimTokens.durationLarge;
        case Anim.StandardExtraLarge:
        case Anim.EmphasizedExtraLarge: return AnimTokens.durationExtraLarge;
        case Anim.FastSpatial:    return AnimTokens.durationFastSpatial;
        case Anim.DefaultSpatial: return AnimTokens.durationDefaultSpatial;
        case Anim.SlowSpatial:    return AnimTokens.durationSlowSpatial;
        case Anim.FastEffects:    return AnimTokens.durationFastEffects;
        case Anim.DefaultEffects: return AnimTokens.durationDefaultEffects;
        case Anim.SlowEffects:    return AnimTokens.durationSlowEffects;
        default: return AnimTokens.durationNormal;
        }
    }

    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        switch (type) {
        case Anim.FastSpatial:    return AnimTokens.curveFastSpatial;
        case Anim.DefaultSpatial: return AnimTokens.curveDefaultSpatial;
        case Anim.SlowSpatial:    return AnimTokens.curveSlowSpatial;
        case Anim.FastEffects:    return AnimTokens.curveFastEffects;
        case Anim.DefaultEffects: return AnimTokens.curveDefaultEffects;
        case Anim.SlowEffects:    return AnimTokens.curveSlowEffects;
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
