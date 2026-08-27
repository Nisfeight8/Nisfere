import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "../core"

Item {
    id: root
    property real uiScale: 1.0
    property int spacing: 10 * uiScale
    property string searchText: ""
    property bool loading: true
    property string activeMode: Colors.mode

    readonly property var filteredThemes: {
        const q = root.searchText.toLowerCase();
        return q === "" ? ThemeActions.themes : ThemeActions.themes.filter(t => t.name.toLowerCase().includes(q));
    }

    readonly property var results: root.filteredThemes.map(t => ({
                id: t.name,
                title: t.name,
                subtitle: (Colors.sourceType === "static" && Colors.sourceName === t.name) ? "Active · " + Colors.mode : "",
                icon: "palette",
                confirmed: Colors.sourceType === "static" && Colors.sourceName === t.name,
                swatches: ["color1", "color2", "color3", "color4", "color5"].map(k => t.colors?.[k] ?? Theme.borderColor)
            }))

    // Applying a theme changes Colors.sourceType/sourceName/mode —
    // which `results` above itself reads (confirmed/subtitle), so the
    // WHOLE array regenerates (new objects) the instant you apply one.
    // ResultsListView's own `onResultsChanged: selectedIndex = 0`
    // treats that as "entirely new results", snapping the highlight
    // back to the top row even though you're still looking at (and
    // just picked) the same theme, just further down the list.
    //
    // Restores selection by matching id (theme name), not index — the
    // list order doesn't change here, only the confirmed/subtitle
    // fields do, but id-matching is correct regardless. Deferred via
    // Qt.callLater so this runs strictly AFTER ResultsListView's own
    // reset, whatever the relative order of the two onResultsChanged
    // handlers actually turns out to be — same pattern already used
    // for a similar ordering race in SearchComponent.
    property string _pendingSelectId: ""
    onResultsChanged: {
        if (root._pendingSelectId === "")
            return;
        const savedId = root._pendingSelectId;
        root._pendingSelectId = "";
        Qt.callLater(() => {
            const idx = root.results.findIndex(r => r.id === savedId);
            if (idx !== -1)
                resultsList.positionAt(idx);
        });
    }

    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    Component.onCompleted: ThemeActions.fetchThemes()

    Connections {
        target: ThemeActions
        function onThemesLoaded() {
            root.loading = false;
        }
    }

    // Width fixed, scaled by uiScale (same as AppLauncherPanel/
    // ClipboardPanel). Height genuinely bottom-up from headerRow +
    // resultsList's own implicit heights — formula stays as-is, only
    // the "+ 10" padding constant needs scaling.
    implicitWidth: 640 * uiScale
    implicitHeight: headerRow.implicitHeight + resultsList.implicitHeight + (10 * uiScale)

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: root.spacing

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 10 * root.uiScale

            Column {
                spacing: 2 * root.uiScale
                Text {
                    text: "Color Themes"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14 * root.uiScale
                    font.bold: true
                }
                Text {
                    text: root.loading ? "Loading..." : root.results.length + " themes available"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    opacity: 0.45
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "Light"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12 * root.uiScale
                opacity: root.activeMode === "light" ? 1.0 : 0.4
            }
            ToggleSwitch {
                uiScale: root.uiScale
                checked: root.activeMode === "dark"
                onToggled: root.activeMode = root.activeMode === "dark" ? "light" : "dark"
            }
            Text {
                text: "Dark"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12 * root.uiScale
                opacity: root.activeMode === "dark" ? 1.0 : 0.4
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        ResultsListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignTop
            results: root.results
            loading: root.loading
            uiScale: root.uiScale
            loadingText: "Loading themes..."
            emptyText: "No matching themes"
            maxListHeight: 400 * root.uiScale
            onResultActivated: (r, index) => {
                const t = root.filteredThemes[index];
                if (t) {
                    root._pendingSelectId = t.name;
                    ThemeActions.setColors(t.name, root.activeMode);
                }
            }
        }
    }
}
