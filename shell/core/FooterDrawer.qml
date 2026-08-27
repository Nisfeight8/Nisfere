import QtQuick
import qs.core
import qs.services

// Extends BaseDrawer instead of duplicating it — everything panel-
// related (geometry, open/close motion, auto-close-on-hover-out,
// mask-relevant panelItem, etc.) is inherited unchanged. This file
// only adds the one thing FooterDrawer has that BaseDrawer doesn't:
// a second sliding shape docked under the panel (footerItem), driven
// by its own component + a bit of independent sizing/gap config.
BaseDrawer {
    id: root

    // ── Footer-specific API ──────────────────────────────────────────
    property Component footerComponent
    property real footerHeight: 56
    property real footerGap: 0 // visible empty space between the two shapes

    readonly property alias footerLoadedItem: footerLoader.item 
    readonly property alias footerItem: footerItem

    Item {
        id: footerItem

        // Same x as panelItem, same width — so it lines up perfectly
        // underneath regardless of panel width changes. `panelItem`
        // here resolves to BaseDrawer's own `property alias panelItem`
        // — inherited, not redeclared.
        x: panelItem.x
        width: panelItem.width
        height: root.footerHeight

        y: panelItem.y + panelItem.height + root.footerGap

        visible: root.offset < 1
        // Slides in slightly behind the main panel (a touch of
        // stagger reads nicer than a dead-simultaneous drop) — purely
        // cosmetic, feel free to tune or remove.
        opacity: 1 - root.offset
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        HoverHandler {
            id: footerHover
            onHoveredChanged: {
                if (hovered && root.opened)
                    root._wasHovered = true;
            }
        }

        Loader {
            id: footerLoader
            anchors.fill: parent
            active: root.opened
            sourceComponent: root.footerComponent
        }
    }
}
