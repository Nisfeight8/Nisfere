pragma Singleton
import Quickshell
import QtQuick

// One shared SystemClock for the whole shell. Bar (and potentially
// ScreenBorder) are meant to eventually run per-screen via
// `Variants { model: Quickshell.screens }` — without this, each
// screen's own Clock widget would spin up its own independent
// SystemClock, exactly the wasted-duplication problem the Quickshell
// docs describe for Process/Timer-based clocks. Every other bar
// widget's data source is already a singleton service (AudioService,
// BatteryService, ...) — this was the one remaining place that wasn't.
Singleton {
    id: root

    property alias date: sysClock.date

    // Minutes, not Seconds — neither consumer (Bar's Clock, MiniClock)
    // ever displays seconds-level detail, both format down to "HH:mm"
    // at most. Seconds precision would re-evaluate every bound
    // expression in every consumer 60x more often than the displayed
    // value ever actually changes — same insight MiniClock's own
    // comment already identified locally; applying it here means every
    // consumer of this shared clock benefits, not just one widget.
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }
}
