import QtQuick
import qs.core
import qs.services

// Karaoke-style 3-line lyric display: faded previous line above, bold
// active line in the middle, faded next line below. Collapses to zero
// height/opacity when LyricsService has no match for the current
// track — harmless to always have mounted.
//
// Readability over the wallpaper: no single theme color guarantees
// contrast against an arbitrary photo (busy images have both light
// and dark regions at once) — so on top of picking foreground/
// foregroundAlt (the theme's actual text-on-background colors,
// rather than the accent color, which is tuned to pop against the
// app's own flat background swatch, not necessarily against a photo),
// every line also gets `style: Text.Outline` — a thin outline drawn
// behind the glyphs that keeps them legible no matter what's directly
// underneath, same idea as video subtitles. Cheap (built into Text,
// no extra render-effect layer needed).
Item {
    id: root

    property color activeColor: Theme.selected
    property color inactiveColor: Theme.foregroundAlt
    property color outlineColor: Qt.rgba(0, 0, 0, 0.65)
    property int fontSizeActive: 24
    property int fontSizeInactive: 15
    property int lineSpacing: 8
    property real inactiveOpacity: 0.65

    anchors {
        left: parent.left
        right: parent.right
    }
    implicitHeight: LyricsService.hasLyrics ? column.implicitHeight : 0

    opacity: LyricsService.hasLyrics ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    readonly property string _prevLine: {
        const i = LyricsService.currentLineIndex - 1;
        return (i >= 0 && i < LyricsService.lines.length) ? LyricsService.lines[i].text : "";
    }
    readonly property string _nextLine: {
        const i = LyricsService.currentLineIndex + 1;
        return (i >= 0 && i < LyricsService.lines.length) ? LyricsService.lines[i].text : "";
    }

    Column {
        id: column
        anchors.centerIn: parent
        width: parent.width * 0.7
        spacing: root.lineSpacing

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.family: Theme.fontName
            font.pixelSize: root.fontSizeInactive
            color: root.inactiveColor
            opacity: root.inactiveOpacity
            style: Text.Outline
            styleColor: root.outlineColor
            text: root._prevLine
        }

        Text {
            id: currentText
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.family: Theme.fontName
            font.pixelSize: root.fontSizeActive
            font.bold: true
            color: root.activeColor
            style: Text.Outline
            styleColor: root.outlineColor
            text: LyricsService.currentLineText

            // Small "pop" whenever the active line advances — cheap
            // and tasteful, avoids needing full crossfade/slide
            // machinery just to signal "new line arrived".
            transform: Scale {
                id: popScale
                origin.x: currentText.width / 2
                origin.y: currentText.height / 2
                xScale: 1
                yScale: 1
            }
            Connections {
                target: LyricsService
                function onCurrentLineIndexChanged() {
                    popAnim.restart();
                }
            }
            SequentialAnimation {
                id: popAnim
                NumberAnimation {
                    targets: [popScale]
                    properties: "xScale,yScale"
                    to: 0.92
                    duration: 90
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    targets: [popScale]
                    properties: "xScale,yScale"
                    to: 1.0
                    duration: 180
                    easing.type: Easing.OutBack
                }
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.family: Theme.fontName
            font.pixelSize: root.fontSizeInactive
            color: root.inactiveColor
            opacity: root.inactiveOpacity
            style: Text.Outline
            styleColor: root.outlineColor
            text: root._nextLine
        }
    }
}
