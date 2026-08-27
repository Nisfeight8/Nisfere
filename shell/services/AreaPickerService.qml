pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property bool active: false
    property var _onSelected: null
    property var _onCancelled: null

    // Ask for a region. onSelected(x, y, w, h) fires on a valid drag,
    // onCancelled() fires on Escape or a too-small/no drag.
    function request(onSelected, onCancelled) {
        if (root.active)
            return; // picker already open, ignore
        root._onSelected = onSelected;
        root._onCancelled = onCancelled;
        root.active = true;
    }

    function finish(x, y, w, h) {
        root.active = false;
        const cb = root._onSelected;
        root._onSelected = null;
        root._onCancelled = null;
        if (cb)
            cb(x, y, w, h);
    }

    function cancel() {
        root.active = false;
        const cb = root._onCancelled;
        root._onSelected = null;
        root._onCancelled = null;
        if (cb)
            cb();
    }
}
