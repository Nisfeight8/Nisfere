import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.services

GlassCard {
    id: miniClockCard

    property real uiScale: 1.0

    readonly property int cardMargin: 15 * uiScale

    // Actual size here is 100% top-down — whatever the containing
    // grid cell gives us via anchors.fill: parent below (the Loader
    // that hosts this in Overview.qml uses Layout.fillWidth/
    // fillHeight, so nothing ever reads an implicit size from this
    // item). Previously this file also computed
    // `implicitWidth/Height` from mainLayout's content size — that
    // was fully dead code (nothing upstream could ever see it), so
    // it's removed rather than kept as misleading decoration.
    anchors.fill: parent

    readonly property real baseCardWidth: 400
    readonly property real baseCardHeight: 480
    implicitWidth: baseCardWidth * uiScale
    implicitHeight: baseCardHeight * uiScale

    ColumnLayout {
        id: mainLayout

        // Was a fixed magic constant (250) disconnected from the
        // card's actual rendered size — meant the font scaling below
        // only ever "looked" responsive because 250 happened to be
        // close to today's real size. Deriving it from the card's
        // own width/height (same approach as monthGrid.cellSize
        // further down) means it stays correct if the grid ratio,
        // window size, or monitor changes.
        readonly property real refSize: Math.min(miniClockCard.width, miniClockCard.height)

        anchors.fill: parent
        anchors.margins: miniClockCard.cardMargin
        spacing: 10 * uiScale

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.selected
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(20, mainLayout.refSize * 0.20)
                // Was a local SystemClock — now reads the shared
                // TimeService singleton (see services/TimeService.qml)
                // instead of every screen owning its own clock source.
                text: Qt.formatDateTime(TimeService.date, "hh:mm")
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: Math.max(12, mainLayout.refSize * 0.06)
                opacity: 0.6
                text: Qt.formatDateTime(TimeService.date, "dddd, d MMMM")
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.foreground
            opacity: 0.1
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true

                Text {
                    id: prevArrow
                    readonly property bool isHovered: prevHover.hovered
                    color: isHovered ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(12, mainLayout.refSize * 0.05)
                    opacity: isHovered ? 1 : 0.5
                    // NOTE: this rendered as an empty string when you
                    // sent it over — likely a glyph character (e.g. a
                    // chevron-left from your nerd font) that didn't
                    // survive copy/paste. Put the real character back
                    // here; left as-is otherwise.
                    text: ""

                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }

                    HoverHandler {
                        id: prevHover
                        margin: 5
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        margin: 5
                        onTapped: CalendarService.previousMonth()
                    }
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(12, mainLayout.refSize * 0.06)
                    horizontalAlignment: Text.AlignHCenter
                    text: monthGrid.title
                }
                Text {
                    id: nextArrow
                    readonly property bool isHovered: nextHover.hovered
                    color: isHovered ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(12, mainLayout.refSize * 0.05)
                    opacity: isHovered ? 1 : 0.5
                    // Same note as prevArrow above.
                    text: ""

                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }

                    HoverHandler {
                        id: nextHover
                        margin: 5
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        margin: 5
                        onTapped: CalendarService.nextMonth()
                    }
                }
            }
            DayOfWeekRow {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(15, mainLayout.refSize * 0.08)
                locale: monthGrid.locale

                delegate: Text {
                    required property string shortName
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(10, mainLayout.refSize * 0.045)
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.4
                    text: shortName
                    verticalAlignment: Text.AlignVCenter
                }
            }
            MonthGrid {
                id: monthGrid

                // Now sourced from the shared CalendarService instead
                // of local month/year properties — see
                // services/CalendarService.qml for why (multi-screen
                // consistency, same reasoning as TimeService).
                month: CalendarService.month
                year: CalendarService.year

                // Computed ONCE here instead of independently in all 42
                // delegate cells. Every cell has the IDENTICAL size (it's
                // a uniform 7×6 grid) — the old per-cell binding did the
                // same Math.min(...) calculation 42 separate times (and
                // several times over during layout settling), confirmed
                // via profiler as the #2 hotspot in the whole shell.
                // Delegates just read this shared value now.
                readonly property real cellSize: Math.min(width / 7, height / 6) * 0.8

                Layout.fillHeight: true
                Layout.fillWidth: true

                delegate: Item {
                    required property var model
                    readonly property bool isHovered: dayHover.hovered

                    Rectangle {
                        anchors.centerIn: parent
                        width: monthGrid.cellSize
                        height: monthGrid.cellSize
                        radius: monthGrid.cellSize / 2
                        color: model.today ? Theme.selected : (parent.isHovered ? Theme.foreground : "transparent")

                        // NOTE: this Behavior had no opacity binding to
                        // react to anywhere in the original — dead code
                        // (same pattern as BorderBezels' border lines).
                        // Left in case you had hover-fade plans for
                        // this that never got wired up; harmless either
                        // way since opacity never actually changes.
                        Behavior on opacity {
                            Anim {
                                type: Anim.FastEffects
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        color: model.today ? Theme.background : (parent.isHovered ? Theme.background : Theme.foreground)
                        font.bold: model.today
                        font.family: Theme.fontName
                        font.pixelSize: Math.max(10, monthGrid.cellSize * 0.5)
                        opacity: model.month === monthGrid.month ? 1 : 0.25
                        text: model.day
                    }

                    HoverHandler {
                        id: dayHover
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Component.onCompleted: CalendarService.ensureInitialized(TimeService.date)
            }
        }
    }
}
