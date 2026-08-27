import QtQuick
import qs.core

// Shared "boolean -> animated 0..1 offset" engine — the same open/close
// Anim pair BaseDrawer and AnimatedContentLoader each reimplement
// locally. Bind your own visual properties (opacity, scale, y, slide
// distance, ...) to `offset`; this component only owns the animation
// itself, not what it's used to animate — the visual mapping differs
// too much between a sliding drawer, a fading+scaling overlay, and a
// fading+sliding bar popup to usefully share that part too.
//
// Root type is Item (not QtObject) specifically so the Anim children
// below can be declared inline — QtObject has no default property to
// hold bare children, Item does (see Anim usage elsewhere in core/).
Item {
    id: root

    // Set this to open/close. 0 = fully open, 1 = fully closed.
    property bool opened: false
    property real offset: 1.0
    property int animType: Anim.DefaultSpatial

    onOpenedChanged: {
        if (opened) {
            closeAnim.stop();
            openAnim.start();
        } else {
            openAnim.stop();
            closeAnim.start();
        }
    }

    Anim {
        id: openAnim
        target: root
        property: "offset"
        to: 0.0
        type: root.animType
    }

    Anim {
        id: closeAnim
        target: root
        property: "offset"
        to: 1.0
        type: root.animType
    }
}
