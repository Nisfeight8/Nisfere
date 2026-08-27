pragma Singleton
import Quickshell
import QtQuick

// Shared "which month is the calendar currently browsing" state — a
// separate singleton from TimeService on purpose: TimeService is the
// read-only wall clock, this is user-navigable browsing state
// (next/previous month). Kept as one shared instance for the same
// reason as TimeService itself — if this widget is ever shown on more
// than one screen, browsing to "next month" on one screen should stay
// in sync everywhere, not just wherever you clicked.
//
// NOTE: because this is a singleton, browsing state now persists
// across the calendar widget closing and reopening (e.g. closing and
// reopening the Dashboard) — navigate to next month, close, reopen
// later the same day, and it's still showing next month rather than
// resetting to today. If you'd rather it always reset to the current
// month on reopen, say so and we'll add that explicitly.
Singleton {
    id: root

    property int month: 0
    property int year: 1970
    property bool initialized: false

    // Called once by the first calendar widget to mount — safe to
    // call from multiple instances/screens, only the FIRST call does
    // anything (subsequent calls are no-ops, so re-opening the widget
    // later doesn't stomp on browsing state you'd already navigated to).
    function ensureInitialized(referenceDate) {
        if (initialized)
            return;
        month = referenceDate.getMonth();
        year = referenceDate.getFullYear();
        initialized = true;
    }

    function nextMonth() {
        if (month === 11) {
            year++;
            month = 0;
        } else {
            month++;
        }
    }
    function previousMonth() {
        if (month === 0) {
            year--;
            month = 11;
        } else {
            month--;
        }
    }
}
