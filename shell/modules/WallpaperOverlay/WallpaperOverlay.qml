import QtQuick
import Quickshell
import qs.core
import qs.services
import "widgets"

// Generic container for anything shown directly over the wallpaper
// (no windows open, nothing else on screen) — visualizer+lyrics+clock.
// Gated only on "is the wallpaper actually showing" (see
// ScreenBorder.qml's Loader) — NOT on whether music is playing, since
// the clock should show regardless of that. The music section gates
// its own visibility on MediaService.isPlaying internally instead.
//
// Layout reasoning (v2 — fixes clock/visualizer sometimes overlapping):
// each element anchors to a DIFFERENT reference point instead of both
// competing for the screen's true center:
//   - Clock: anchored near the TOP (independent of center entirely)
//   - Visualizer: anchored at the screen's true center — this is now
//     its own anchor point, not shared with the clock, so however
//     tall the clock's text happens to render, it can never reach
//     down into the visualizer's space.
//   - Lyrics: hang below the Visualizer's own bottom edge, not
//     anchored to the screen at all — they just follow wherever the
//     visualizer actually ends up.
Item {
    id: root

    anchors.fill: parent

    // ── Clock/Date widget — near the top, independent of center ────
    ClockWidget {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Theme.scaledBarHeight(QsWindow.window?.screen) + 100
        }
    }

    // ── Music section (visualizer + lyrics) ───────────────────────
    Item {
        id: musicSection

        property int gap: 20
        property int visualizerHeight: 200

        anchors.fill: parent
        visible: MediaService.isPlaying
        opacity: MediaService.isPlaying ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        // Only created while music is actually playing — same reason
        // AudioVisualizer.isActive gates cava itself: no point paying
        // for a component (or the process behind it) nobody can see.
        //
        // Anchored to the screen's TRUE CENTER — this is its own
        // anchor point now, not shared with the clock or anything
        // else, so it always lands dead-center regardless of how
        // tall the clock or lyrics happen to be.
        Loader {
            id: visualizerLoader
            anchors.centerIn: parent
            width: parent.width
            height: musicSection.visualizerHeight
            active: MediaService.isPlaying
            sourceComponent: Component {
                WallpaperVisualizer {}
            }
        }

        // Only created when LyricsService actually has a match for
        // the current track — no dead Text/Behavior/Connections tree
        // sitting around for songs with no lyrics found. Positioned
        // relative to the VISUALIZER's own bottom edge, not the
        // screen — it just follows the visualizer wherever it is.
        Loader {
            id: lyricsLoader
            anchors {
                top: visualizerLoader.bottom
                topMargin: musicSection.gap + 100
                left: parent.left
                right: parent.right
            }
            height: item ? item.implicitHeight : 0
            active: LyricsService.hasLyrics
            sourceComponent: Component {
                WallpaperLyrics {}
            }
        }
    }
}
