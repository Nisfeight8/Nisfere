import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "../core"

Item {
    id: root
    property real uiScale: 1.0

    property string searchText: ""

    readonly property var filteredEntries: root.searchText === "" ? ClipboardService.entries : ClipboardService.entries.filter(e => e.preview.toLowerCase().includes(root.searchText.toLowerCase()))

    readonly property var results: root.filteredEntries.map(e => ({
                id: "clip-" + e.id,
                title: e.preview,
                icon: "clipboard",
                actions: [
                    {
                        icon: "x",
                        trigger: () => ClipboardService.deleteEntry(e.raw)
                    }
                ],
                raw: e.raw
            }))

    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    Component.onCompleted: ClipboardService.refresh()

    // Width fixed, scaled by uiScale (same as AppLauncherPanel).
    // Height genuinely bottom-up from header + divider + resultsList's
    // own implicit height — that formula stays as-is, only its
    // constituent margins/spacing below need scaling.
    implicitWidth: 420 * uiScale
    implicitHeight: headerRow.implicitHeight + dividerRect.height + resultsList.implicitHeight + (mainColumn.spacing * 2) + (mainColumn.anchors.margins * 2)

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 12 * root.uiScale
        spacing: 8 * root.uiScale

        // ── Header ────────────────────────────────────────────────
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 6 * root.uiScale

            LucideIcon {
                icon: "clipboard-list"
                size: 14 * root.uiScale
                color: Theme.selected
            }

            Text {
                Layout.fillWidth: true
                leftPadding: 4 * root.uiScale
                text: ClipboardService.loading ? "Loading..." : ClipboardService.entries.length + " item" + (ClipboardService.entries.length !== 1 ? "s" : "")
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13 * root.uiScale
                font.bold: true
            }

            IconButton {
                icon: "refresh-cw"
                size: 28 * root.uiScale
                iconSize: 13 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                tooltipText: "Refresh"
                spinning: ClipboardService.loading
                onTapped: ClipboardService.refresh()
            }

            IconButton {
                icon: "trash-2"
                size: 28 * root.uiScale
                iconSize: 13 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                visible: ClipboardService.entries.length > 0
                hoverColor: Theme.color1
                activeColor: Theme.color1
                tooltipText: "Clear all"
                onTapped: ClipboardService.wipeAll()
            }
        }

        Rectangle {
            id: dividerRect
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // ── List ──────────────────────────────────────────────────
        ResultsListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            uiScale: root.uiScale
            results: root.results
            loading: ClipboardService.loading
            loadingText: "Loading..."
            emptyText: root.searchText !== "" ? "No matching clipboard entries" : "No clipboard history"
            maxListHeight: 400 * root.uiScale
            onResultActivated: (r, index) => {
                ClipboardService.copyEntry(r.raw);
                ShellState.closeDashboard();
            }
        }
    }
}
