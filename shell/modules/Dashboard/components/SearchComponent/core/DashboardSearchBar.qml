import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    implicitHeight: 40 * uiScale

    signal keyPressed(var event)
    signal accepted
    signal escapePressed

    readonly property alias text: searchBar.text
    readonly property alias input: searchBar.input

    readonly property var activeProvider: SearchProviders.findById(ShellState.dashboardSearchProviderId)

    readonly property bool _pickerPanelOpen: ShellState.dashboardSearchDrilldownPanelId === "providerPicker"

    RowLayout {
        anchors.fill: parent
        spacing: 8 * root.uiScale

        SearchBar {
            id: searchBar
            Layout.fillWidth: true
            placeholderText: placeholderCycle.currentText
            uiScale: root.uiScale
            property bool _isSyncingFromState: false

            Component.onCompleted: {
                _isSyncingFromState = true;
                text = ShellState.dashboardSearchText;
                _isSyncingFromState = false;
                input.forceActiveFocus();
            }

            onTextChanged: {
                if (_isSyncingFromState)
                    return;

                const exactKeywordMatch = SearchProviders.keywordProviders.find(p => p.keyword === text);
                if (exactKeywordMatch) {
                    text = text + " ";
                    input.cursorPosition = text.length;
                    return;
                }

                if (ShellState.dashboardSearchHasDrilldown)
                    ShellState.closeSearchDrilldown();

                ShellState.dashboardSearchText = text;
            }

            Connections {
                target: ShellState
                function onDashboardSearchTextChanged() {
                    if (searchBar.text !== ShellState.dashboardSearchText) {
                        searchBar._isSyncingFromState = true;
                        searchBar.text = ShellState.dashboardSearchText;
                        searchBar._isSyncingFromState = false;
                    }
                }
            }

            onKeyPressed: e => {
                if (e.key === Qt.Key_Escape) {
                    root.escapePressed();
                    e.accepted = true;
                    return;
                }
                if (e.key === Qt.Key_Backspace) {
                    const kw = SearchProviders.keywordProviders.find(p => text === p.keyword + " ");
                    if (kw) {
                        text = "";
                        e.accepted = true;
                        return;
                    }
                }
                if (e.key === Qt.Key_Left && input.cursorPosition !== 0)
                    return;
                if (e.key === Qt.Key_Right && input.cursorPosition !== text.length)
                    return;
                root.keyPressed(e);
            }
            onAccepted: root.accepted()
        }

        Rectangle {
            id: providerBtn
            width: 40 * root.uiScale
            height: 40 * root.uiScale
            radius: Theme.radius
            color: pickerHover.hovered || root._pickerPanelOpen ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : Theme.backgroundAlt
            border.width: 1
            border.color: Theme.borderColor
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            LucideIcon {
                anchors.centerIn: parent
                icon: root.activeProvider ? root.activeProvider.icon : "layout-grid"
                size: 17 * root.uiScale
                color: root._pickerPanelOpen ? Theme.selected : Theme.foreground
            }
            HoverHandler {
                id: pickerHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: {
                    if (root._pickerPanelOpen)
                        ShellState.closeSearchDrilldown();
                    else
                        ShellState.openSearchDrilldown("providerPicker", ShellState.dashboardSearchProviderId);
                }
            }
        }
    }

    Item {
        id: placeholderCycle
        property var texts: ["Search apps..."].concat(SearchProviders.keywordProviders.map(p => "Try \"" + p.keyword + "\" for " + p.label.toLowerCase() + "..."))
        property int idx: 0
        readonly property string currentText: searchBar.text === "" ? texts[idx] : ""

        Timer {
            interval: 2500
            running: searchBar.text === ""
            repeat: true
            onTriggered: placeholderCycle.idx = (placeholderCycle.idx + 1) % placeholderCycle.texts.length
        }
    }
}
