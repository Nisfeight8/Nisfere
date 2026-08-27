import QtQuick
import qs.core
import qs.services

// A CustomSlider wired to MediaService — same thin-track visuals (see
// CustomSlider.qml), just bound to the current player's position/length
// instead of a free-standing value, plus seeking on release. Used to be
// a byte-for-byte copy of CustomSlider with this wiring bolted on; any
// visual fix to CustomSlider now applies here automatically instead of
// needing to be duplicated by hand every time.
CustomSlider {
    id: control

    to: MediaService.hasPlayer ? MediaService.length : 1

    Binding {
        target: control
        property: "value"
        value: MediaService.hasPlayer ? MediaService.position : 0
        when: !control.pressed
        restoreMode: Binding.RestoreNone
    }

    onMoved: {
        if (MediaService.hasPlayer)
            MediaService.seek(value);
    }
}
