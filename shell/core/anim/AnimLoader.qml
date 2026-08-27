import QtQuick
import qs.core

// Fade-swap loader for tab/page content inside a drawer.
//
// Sequence: fade OUT (real duration, not instant) → swap sourceComponent
// (the container's size, driven by this Loader's implicitWidth/Height via
// the drawer's geometry chain, updates HERE — while opacity is ~0) → once
// the new component is Ready, fade IN.
//
// This "resize while invisible" ordering is what prevents the drawer's
// container from visibly growing/shrinking underneath centered content
// during a tab switch — by the time the new content fades in, the
// container has already snapped to the correct size.
Loader {
    id: root

    property Component sourceComp
    property bool isComplete

    property bool _waitingForLoad: false
    asynchronous: true

    onSourceCompChanged: {
        if (!isComplete)
            return;
        fadeInAnim.stop();
        if (fadeOutAnim.running) {
            // Already mid-transition (fast tab switching) — snap to 0
            // and queue the new load immediately rather than stacking anims.
            fadeOutAnim.stop();
            opacity = 0;
            _waitingForLoad = true;
            sourceComponent = sourceComp;
        } else {
            fadeOutAnim.restart();
        }
    }

    onStatusChanged: {
        if (status === Loader.Ready && _waitingForLoad) {
            _waitingForLoad = false;
            fadeInAnim.start();
        }
    }

    Component.onCompleted: {
        isComplete = true;
        sourceComponent = sourceComp;
    }

    SequentialAnimation {
        id: fadeOutAnim
        Anim {
            target: root
            property: "opacity"
            to: 0
            type: Anim.FastEffects
        }
        ScriptAction {
            script: {
                // Swap happens here, fully hidden — the container's size
                // (bound to this Loader's new implicitWidth/Height via
                // the drawer's contentSizeChanged chain) updates in this
                // same instant, invisibly.
                root._waitingForLoad = true;
                root.sourceComponent = root.sourceComp;
            }
        }
    }

    Anim {
        id: fadeInAnim
        target: root
        property: "opacity"
        to: 1
        type: Anim.DefaultEffects
    }
}
