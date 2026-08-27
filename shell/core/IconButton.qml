import QtQuick
import qs.core

// Generic small icon-only button — covers every square/rounded icon
// button pattern in the shell: hover-tint (refresh), toggle/solid-active
// (DND), always-bordered (clear-all), hover-solid (popup close), and
// fixed icon color (destructive actions that stay red regardless of state).
Rectangle {
    id: root

    property string icon: ""
    property int size: 32
    property int iconSize: 16
    property string tooltipText: ""
    property bool enabled: true

    radius: Theme.radius   // dynamic from Theme — override per-instance when a smaller radius is needed

    // ── State ────────────────────────────────────────────────────
    property bool isActive: false   // persistent toggle state (e.g. DND on)
    property bool activeSolid: false   // true: solid activeColor fill when active
    // false: tinted activeColor fill when active
    property bool hoverSolid: false   // true: solid hoverColor fill on hover
    // (instead of the default tint)
    property bool alwaysBorder: false  // true: static Theme.borderColor border,

    // ignoring hover/active (e.g. clear-all button)

    // ── Colors ───────────────────────────────────────────────────
    property color borderColor: Theme.foreground
    property color normalColor: "transparent"
    property color hoverColor: Theme.selected
    property color activeColor: Theme.selected
    property color contrastColor: Theme.background   // icon color on solid fills
    property color fixedIconColor: "transparent"      // alpha>0 = force this icon color always

    // ── Idle appearance ──────────────────────────────────────────
    property real idleOpacity: 0.6   // icon opacity when neither hovered nor active
    property bool dimWhenIdle: true  // false = icon always full opacity (e.g. destructive actions)
    property bool spinning: false // true = icon rotates continuously (e.g. loading state)
    property bool flat: false // true = no background/border ever — icon only (e.g. media controls)

    readonly property bool pressed: tap.pressed

    readonly property bool isHovered: hover.hovered

    signal tapped

    width: size
    height: size

    color: {
        if (flat)
            return "transparent";
        if (isActive && activeSolid)
            return activeColor;
        if (isActive)
            return Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.40);
        if (isHovered && hoverSolid)
            return hoverColor;
        if (isHovered)
            return Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.40);
        return normalColor;
    }
    border.width: flat ? 0 : alwaysBorder ? Theme.widgetBorderWidth : ((isActive || isHovered) ? 1 : 0)
    border.color: alwaysBorder ? borderColor : (isActive ? activeColor : hoverColor)

    Behavior on color {
        AnimColor {
            type: Anim.FastEffects
        }
    }
    Behavior on border.color {
        AnimColor {
            type: Anim.FastEffects
        }
    }
    Behavior on border.width {
        Anim {
            type: Anim.FastEffects
        }
    }

    LucideIcon {
        id: iconItem
        anchors.centerIn: parent
        // Swapped to a dedicated spinner glyph while spinning, instead
        // of rotating whatever icon the button normally shows. Most
        // icons (play, refresh-cw, ...) have an inherent up/down
        // orientation — rotating them looks wrong at almost every
        // angle, not just when stopped. loader-circle has none, so it
        // reads correctly through the whole rotation AND at rest.
        icon: root.spinning ? "loader-circle" : root.icon
        size: root.iconSize

        color: {
            // Solid-fill states need a contrasting icon color, so they
            // take priority over fixedIconColor (which is for the idle state).
            if (root.isActive && root.activeSolid)
                return root.contrastColor;
            if (root.isHovered && root.hoverSolid)
                return root.contrastColor;
            if (root.fixedIconColor.a > 0)
                return root.fixedIconColor;
            if (root.isActive)
                return root.activeColor;
            if (root.isHovered)
                return root.hoverColor;
            if (root.borderColor != Theme.borderColor)
                return root.borderColor;
            return Theme.foreground;
        }
        opacity: {
            if (root.spinning)
                return 0.35;
            if (!root.dimWhenIdle)
                return 1.0;
            return (root.isActive || root.isHovered) ? 1.0 : root.idleOpacity;
        }

        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }

        NumberAnimation {
            target: iconItem
            property: "rotation"
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.spinning
            // Was a RotationAnimator, reset via root's onSpinningChanged
            // — RotationAnimator runs on the render thread, which
            // doesn't reliably synchronize with a direct property write
            // from the GUI thread (root.spinning changing and our reset
            // could race against the animator's own last write). A
            // plain NumberAnimation runs on the GUI thread like any
            // other property write, and resetting HERE (in the
            // animation's own onRunningChanged, which only fires once
            // it has actually fully stopped) removes the race entirely
            // — guaranteed to happen after, not possibly before/during.
            onRunningChanged: {
                if (!running)
                    iconItem.rotation = 0;
            }
        }
    }

    HoverHandler {
        id: hover
        // Was missing — without this, hover kept firing (and driving
        // every color/opacity computation above) even while disabled,
        // so a "disabled" button still visually reacted to hover, just
        // without responding to taps. Only cursorShape depended on
        // `enabled` before; now the handler itself does too.
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: root.tapped()
    }
    StyledToolTip {
        visible: root.isHovered && root.tooltipText !== ""
        text: root.tooltipText
    }
}
