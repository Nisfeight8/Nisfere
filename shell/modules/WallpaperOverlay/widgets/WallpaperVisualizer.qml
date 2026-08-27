import QtQuick
import qs.core
import qs.services

// Bass-reactive bar visualizer for the wallpaper, mirrored outward
// from the center like a symmetric spectrum display, spanning the
// full width of the screen.
//
// IMPORTANT: this Item is meant to be lazily created/destroyed by a
// Loader in ScreenBorder.qml (active only while music is playing AND
// the wallpaper is actually visible on that screen) — it does nothing
// on its own to gate cava; it just renders whatever AudioVisualizer.bars
// currently holds. See AudioVisualizer.qml's `anyScreenShowingWallpaper`
// for the actual isActive gating that starts/stops cava itself.
Item {
    id: root

    // ── Tunables ─────────────────────────────────────────────────
    property int barSpacing: 3
    // Clamp so bar thickness stays reasonable on ultrawide/4K screens
    // instead of growing absurdly thick just because there's room —
    // set maxBarWidth higher (or Infinity) if you actually want it to
    // always fill edge-to-edge regardless of screen size.
    property real minBarWidth: 3
    // Was unbounded — with a low cava bar count (e.g. bars=10 →
    // 20 mirrored) spread across a full screen width, each bar ended
    // up 80-100px wide, and radius: width/2 turned them into giant
    // circles instead of bars (see conversation screenshot). Capped
    // back to a sane bar-like thickness; raise cava.conf's `bars`
    // count instead if you want more/thinner bars rather than raising
    // this.
    property real maxBarWidth: 20
    // Fixed rounded-cap radius instead of width/2 — keeps bars looking
    // like bars (pill-shaped ends) even if width ever changes, rather
    // than "circle vs bar" depending entirely on bar count/screen size.
    property real barRadius: 4
    property real maxBarHeight: 260
    property color peakColor: Theme.selected
    property color baseColor: Theme.foreground
    property real rawMax: 1000
    property int fadeInMs: 250

    anchors.fill: parent

    readonly property var mirroredBars: {
        const b = AudioVisualizer.bars;
        if (!b || b.length === 0)
            return [];
        return b.slice().reverse().concat(b);
    }

    readonly property int barCount: root.mirroredBars.length

    // Even distribution across the full available width. Clamped to
    // [minBarWidth, maxBarWidth] so a low bar count on a huge screen
    // doesn't stretch into cartoonishly thick blocks.
    readonly property real computedBarWidth: {
        if (root.barCount === 0)
            return root.minBarWidth;
        const raw = (root.width - root.barSpacing * (root.barCount - 1)) / root.barCount;
        return Math.max(root.minBarWidth, Math.min(root.maxBarWidth, raw));
    }

    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity {
        NumberAnimation {
            duration: root.fadeInMs
            easing.type: Easing.OutCubic
        }
    }

    Row {
        id: barsRow
        // Centered rather than force-stretched — when computedBarWidth
        // hits the max clamp on a huge screen, the row will be
        // narrower than root.width, and centering looks intentional
        // instead of leaving a lopsided gap on one side.
        anchors.centerIn: parent
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            delegate: Rectangle {
                id: bar

                required property int index
                readonly property real rawVal: root.mirroredBars[index] ?? 0
                readonly property real normalized: Math.max(0, Math.min(1, rawVal / root.rawMax))

                width: root.computedBarWidth
                // Small non-zero floor so bars never fully disappear
                // between beats — reads as "idle breathing" instead of
                // flickering on/off.
                height: Math.max(width, normalized * root.maxBarHeight)
                radius: root.barRadius
                anchors.verticalCenter: parent.verticalCenter

                // Louder bars glow brighter/warmer (toward peakColor),
                // quiet ones sit closer to the plain foreground color —
                // gives the whole thing a subtle pulse with the music
                // instead of flat single-color bars.
                color: Qt.tint(root.baseColor, Qt.rgba(root.peakColor.r, root.peakColor.g, root.peakColor.b, normalized * 0.75))

                Behavior on height {
                    NumberAnimation {
                        duration: 70
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 90
                    }
                }
            }
        }
    }
}
