import QtQuick
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

// Large centered wallpaper clock/date, meant to sit in WallpaperOverlay's
// reserved center slot.
//
// Sourced from the shared TimeService singleton (SystemClock at
// Minutes precision) rather than keeping its own Timer — this widget
// lives inside ScreenBorder's per-screen Variants, so a self-managed
// Timer here would spin up one independent clock PER MONITOR, exactly
// the wasted-duplication problem TimeService's own comment already
// describes. One shared SystemClock, every screen's ClockWidget just
// reads from it.
//
// Readability: same underlying problem as WallpaperLyrics.qml — no
// theme color guarantees contrast against an arbitrary photo. Uses a
// soft DropShadow instead of a hard Text.Outline though (unlike the
// lyrics) — this is the single largest, most prominent element on the
// wallpaper, so a gentle shadow reads as "designed" (think macOS/
// iOS lock-screen clocks) rather than the harder subtitle-style
// outline that suits smaller, denser lyric text better.
Item {
    id: root

    property color timeColor: Theme.foreground
    property color dateColor: Theme.foreground
    property color dividerColor: Theme.selected
    property int timeFontSize: 96
    property int dateFontSize: 22
    property real dateOpacity: 0.75
    property int spacing: 10
    property int dividerWidth: 36

    // Qt.formatTime/formatDate respect the system locale automatically
    // (same as the bar's own clock), so this matches whatever format
    // the rest of the shell already shows without hardcoding anything
    // locale-specific here.
    readonly property string timeText: Qt.formatTime(TimeService.date, "HH:mm")
    readonly property string dateText: Qt.formatDate(TimeService.date, "dddd, d MMMM")

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column
        anchors.centerIn: parent
        spacing: root.spacing

        // Single shadow layer for the whole group — cheaper than
        // shadowing each Text separately, and keeps the two lines
        // reading as one cohesive unit rather than two independently
        // "floating" pieces.
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 3
            radius: 16
            samples: 33
            color: Qt.rgba(0, 0, 0, 0.55)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeText
            color: root.timeColor
            font.family: Theme.fontName
            font.pixelSize: root.timeFontSize
            font.bold: true
            font.letterSpacing: 2
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.dividerWidth
            height: 3
            radius: 1.5
            color: root.dividerColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: root.dateColor
            opacity: root.dateOpacity
            font.family: Theme.fontName
            font.pixelSize: root.dateFontSize
        }
    }
}
