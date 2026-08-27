import QtQuick
import qs.core
import qs.services
import "../core"

Item {
    id: root
    property real uiScale: 1.0

    property string searchText: ""

    // 1 second of no typing before actually searching — the loading
    // indicator starts exactly then too (search() itself sets
    // FileSearchService.loading), no separate early poke on every
    // keystroke.
    Timer {
        id: debounceTimer
        interval: 1000
        onTriggered: FileSearchService.search(root.searchText)
    }
    onSearchTextChanged: debounceTimer.restart()

    // onSearchTextChanged does NOT fire for the initial value at
    // creation (only for later changes) — without this, reopening the
    // panel showed whatever FileSearchService.results/loading were
    // left over from the LAST session (the service is a singleton,
    // its state persists across panel open/close), even though
    // searchText itself correctly reset to empty. Runs the same
    // search()/clear logic immediately instead of waiting on a change
    // event that was never going to come.
    Component.onCompleted: FileSearchService.search(root.searchText)

    readonly property var results: FileSearchService.results.map(r => ({
                id: r.path,
                title: r.name,
                subtitle: r.path,
                icon: r.isDir ? "folder" : "file",
                actions: r.isDir ? [] : [
                    {
                        icon: "folder-open",
                        trigger: () => {
                            FileSearchService.openContainingFolder(r.path);
                            ShellState.closeDashboard();
                        }
                    }
                ],
                action: () => FileSearchService.openFile(r.path)
            }))

    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    // Width fixed, scaled by uiScale (same as AppLauncherPanel/
    // ClipboardPanel/ColorsPanel). Height genuinely bottom-up from
    // resultsList's own implicit height.
    implicitWidth: 640 * uiScale
    implicitHeight: resultsList.implicitHeight

    ResultsListView {
        id: resultsList
        uiScale: root.uiScale
        anchors.fill: parent
        results: root.results
        loading: FileSearchService.loading
        loadingText: "Searching..."
        emptyText: {
            if (FileSearchService.errorMessage !== "")
                return FileSearchService.errorMessage;
            if (root.searchText.trim() === "")
                return "Type to search files";
            if (root.searchText.trim().length < FileSearchService.minQueryLength)
                return "Keep typing...";
            return "No matching files";
        }
        maxListHeight: 400 * root.uiScale
        onResultActivated: (r, index) => {
            if (r.action)
                r.action();
            ShellState.closeDashboard();
        }
    }
}
