import QtQuick
import Quickshell
import QtQuick.Controls.impl

IconImage {
    id: root

    property string icon: "activity"
    property int size: 24
    
    source: icon ? Quickshell.shellDir + "/assets/icons/" + icon + ".svg" : ""
    sourceSize.width: size
    sourceSize.height: size

    // Re-enabled — the intermittent "sometimes doesn't show" issue was
    // very likely an async race, not a caching bug: if `icon` changes
    // twice in quick succession (e.g. an initial "" before the real
    // binding settles), asynchronous decode of the FIRST request can
    // complete AFTER the second one starts, so the wrong/stale result
    // wins. Disabling cache made every load "fresh" (masking the race)
    // but at the cost of re-decoding the same SVGs repeatedly —
    // confirmed via QML Profiler as dozens of redundant PixmapCache
    // reloads for icons used across many buttons (palette, chevron-
    // right, camera, ...).
    //
    // Forcing synchronous loading closes the race directly instead:
    // for icons this small (~24px SVGs), synchronous decode is
    // effectively instant, so there's no real cost to not being async,
    // and now there's no window for a stale async result to win.
    asynchronous: true
    cache: true

    color: "white"
}
