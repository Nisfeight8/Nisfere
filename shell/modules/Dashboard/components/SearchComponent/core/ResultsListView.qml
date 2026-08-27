import QtQuick
import qs.core

Item {
    id: root
    property real uiScale: 1.0

    required property var results

    property string emptyText: "No results"
    property string loadingText: ""
    property bool loading: false

    // Mirrors SearchResultRow's own height: 56 * uiScale — kept as one
    // named constant so the two can't silently drift apart. If
    // SearchResultRow's height formula ever changes, update both
    // together.
    readonly property int rowHeight: 56 * uiScale
    readonly property int rowSpacing: 4 * uiScale
    property int emptyStateHeight: 90 * uiScale
    property int maxListHeight: 400 * uiScale

    signal resultActivated(var result, int index)

    property int selectedIndex: 0

    readonly property int listContentHeight: results.length === 0 ? emptyStateHeight : Math.min(list.contentHeight || (results.length * rowHeight + Math.max(0, results.length - 1) * rowSpacing), maxListHeight)

    implicitWidth: 640 * uiScale
    implicitHeight: listContentHeight

    function navigate(delta) {
        if (root.results.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(root.results.length - 1, selectedIndex + delta));
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
    function activateSelected() {
        const r = root.results[selectedIndex];
        if (r)
            root.resultActivated(r, selectedIndex);
    }

    // For callers that need to restore selection to a specific index
    // AFTER `results` has changed (e.g. re-selecting the same item by
    // id once a provider's results array regenerates due to
    // Colors.sourceType/wallpaper/etc changing — see ColorsPanel/
    // WallpapersPanel) — plain `selectedIndex = idx` only updates
    // which row is highlighted, it doesn't scroll the ListView to it.
    // If the list's own scroll position had already reset to the top
    // (which appears to happen whenever the underlying model gets a
    // new array reference, even with identical content), the
    // highlighted row could end up correct but off-screen, or briefly
    // visible jumping from the top row down to it. This does both
    // together in one call, same as navigate() already does for
    // keyboard movement.
    function positionAt(index) {
        if (index < 0 || index >= root.results.length)
            return;
        selectedIndex = index;
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    onResultsChanged: selectedIndex = 0

    Text {
        anchors.centerIn: parent
        visible: root.loading || root.results.length === 0
        text: root.loading && root.loadingText !== "" ? root.loadingText : root.emptyText
        color: Theme.foreground
        opacity: 0.4
        font.family: Theme.fontName
        font.pixelSize: 13 * root.uiScale
        horizontalAlignment: Text.AlignHCenter
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        visible: root.results.length > 0 && !root.loading
        spacing: root.rowSpacing
        model: root.results
        delegate: SearchResultRow {
            required property var modelData
            required property int index
            result: modelData
            isSelected: index === root.selectedIndex
            uiScale: root.uiScale
            onActivated: {
                root.selectedIndex = index;
                root.activateSelected();
            }
        }
    }
}
