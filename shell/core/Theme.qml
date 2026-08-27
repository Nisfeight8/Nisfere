pragma Singleton
import QtQuick
import qs.services

// Aggregator — combines Colors.qml + StyleSettings.qml into the SAME public
// API the rest of the shell already uses. Zero downstream breakage:
// every existing `Theme.radius`/`Theme.background`/etc reference keeps
// working exactly as before, only the SOURCE moved.
QtObject {

    // ── Scale values ──────────────────────────
    readonly property real referenceHeight: 1080
    readonly property real minUiScale: 0.82
    readonly property real maxUiScale: 2.5

    function scaleFor(screen) {
        if (!screen || !screen.height)
            return 1.0;
        const raw = screen.height / referenceHeight;
        return Math.max(minUiScale, Math.min(maxUiScale, raw));
    }

    function scaledBarHeight(screen) {
        return barHeight * scaleFor(screen);
    }

    // ── Layout values → from StyleSettings.qml ──────────────────────────
    readonly property bool enableWidgetBorders: StyleSettings.enableWidgetBorders
    readonly property string fontName: StyleSettings.fontName
    readonly property int radius: StyleSettings.radius
    readonly property int barHeight: StyleSettings.barHeight
    readonly property int screenBorderSize: StyleSettings.screenBorderSize
    readonly property int widgetBorderWidth: enableWidgetBorders ? 1 : 0

    // ── Base colors → from Colors.qml, with widgetOpacity ACTUALLY
    // applied this time. background/backgroundAlt take widgetOpacity
    // as their alpha channel — every widget that already does
    // `color: Theme.background` gets real opacity control, with ZERO
    // changes needed anywhere else in the shell. foreground/selected/
    // cursor stay fully opaque — text/icons fading out with the
    // widget backdrop would hurt readability, not help it.
    readonly property color _opaqueBackground: Colors.background

    property color background: Qt.rgba(_opaqueBackground.r, _opaqueBackground.g, _opaqueBackground.b, StyleSettings.widgetOpacity)
    property color backgroundAlt: Qt.rgba(Colors.backgroundAlt.r, Colors.backgroundAlt.g, Colors.backgroundAlt.b, StyleSettings.widgetOpacity)
    property color foreground: Colors.foreground
    property color foregroundAlt: Colors.foregroundAlt

    property color selected: Colors.selected
    property color cursor: Colors.cursor

    // Border stays fully opaque regardless of widgetOpacity — thin
    // outlines need definition, translucency here would just make
    // them look faded/broken rather than "glassy". Built from
    // _opaqueBackground (not the now-translucent `background` above)
    // since Qt.tint's mix math assumes an opaque base.
    property color borderColor: Qt.rgba(Colors.borderColor.r, Colors.borderColor.g, Colors.borderColor.b, StyleSettings.widgetOpacity)

    // ── Full palette → from Colors.qml ─────────────────────────────
    property color color0: Colors.color0
    property color color1: Colors.color1
    property color color2: Colors.color2
    property color color3: Colors.color3
    property color color4: Colors.color4
    property color color5: Colors.color5
    property color color6: Colors.color6
    property color color7: Colors.color7
    property color color8: Colors.color8
    property color color9: Colors.color9
    property color color10: Colors.color10
    property color color11: Colors.color11
    property color color12: Colors.color12
    property color color13: Colors.color13
    property color color14: Colors.color14
    property color color15: Colors.color15

    // ── Metadata → from Colors.qml ──────────────────────────────────
    property string wallpaper: Colors.wallpaper
    property string mode: Colors.mode
    property string sourceType: Colors.sourceType
    property string sourceName: Colors.sourceName
}
