import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    implicitWidth: 820 * uiScale
    implicitHeight: 600 * uiScale
    
    focus: true
    anchors.fill: parent

    property string filterCategory: "all"
    property string searchQuery: ""
    property string sortKey: "memMb"
    property bool sortDescending: true

    property var displayList: []
    property var expandedGroups: ({})

    function toggleExpanded(name) {
        let copy = Object.assign({}, expandedGroups);
        copy[name] = !copy[name];
        expandedGroups = copy;
    }

    function _recomputeGroups() {
        let list = ProcessMonitorService.processes;

        if (filterCategory === "user")
            list = list.filter(p => !p.isSystem);
        else if (filterCategory === "system")
            list = list.filter(p => p.isSystem);

        if (searchQuery.trim() !== "") {
            const q = searchQuery.toLowerCase();
            list = list.filter(p => p.name.toLowerCase().includes(q));
        }

        const groupMap = {};
        for (const p of list) {
            let g = groupMap[p.name];
            if (!g) {
                g = {
                    name: p.name,
                    cpuPercent: 0,
                    memMb: 0,
                    isSystem: p.isSystem,
                    pid: p.pid,
                    children: []
                };
                groupMap[p.name] = g;
            }
            g.cpuPercent += p.cpuPercent;
            g.memMb += p.memMb;
            g.children.push(p);
        }

        const grouped = Object.values(groupMap);
        for (const g of grouped) {
            g.cpuPercent = Math.round(g.cpuPercent * 10) / 10;
            g.memMb = Math.round(g.memMb * 10) / 10;
            g.count = g.children.length;
        }
        return grouped;
    }

    function _sortGroups(grouped) {
        grouped.sort((a, b) => {
            let av = a[root.sortKey], bv = b[root.sortKey];
            if (typeof av === "string") {
                av = av.toLowerCase();
                bv = bv.toLowerCase();
            }
            if (av < bv)
                return root.sortDescending ? 1 : -1;
            if (av > bv)
                return root.sortDescending ? -1 : 1;
            return 0;
        });
        return grouped;
    }

    function _updateDisplayListSorted() {
        displayList = _sortGroups(_recomputeGroups());
    }

    function _updateDisplayListLive() {
        const grouped = root._recomputeGroups();
        if (!listHoverHandler.hovered) {
            displayList = root._sortGroups(grouped);
            return;
        }
        const byName = new Map(grouped.map(g => [g.name, g]));
        const ordered = [];
        for (const prev of root.displayList) {
            if (byName.has(prev.name)) {
                ordered.push(byName.get(prev.name));
                byName.delete(prev.name);
            }
        }
        for (const g of byName.values())
            ordered.push(g);
        displayList = ordered;
    }

    onSearchQueryChanged: _updateDisplayListSorted()
    onFilterCategoryChanged: _updateDisplayListSorted()
    onSortKeyChanged: _updateDisplayListSorted()
    onSortDescendingChanged: _updateDisplayListSorted()
    Connections {
        target: ProcessMonitorService
        function onProcessesChanged() {
            root._updateDisplayListLive();
        }
    }

    Component.onCompleted: {
        ProcessMonitorService.polling = true;
        ProcessMonitorService.refresh();
        _updateDisplayListSorted();
    }
    Component.onDestruction: ProcessMonitorService.polling = false
    Keys.onEscapePressed: ShellState.closeDashboard()

    function sortBy(key) {
        if (root.sortKey === key)
            root.sortDescending = !root.sortDescending;
        else {
            root.sortKey = key;
            root.sortDescending = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14 * root.uiScale

        // ── Header ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16 * root.uiScale

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 12 * root.uiScale

                Rectangle {
                    width: 44 * root.uiScale
                    height: 44 * root.uiScale
                    radius: 12 * root.uiScale
                    color: Theme.backgroundAlt
                    border.width: 1
                    border.color: Theme.borderColor
                    LucideIcon {
                        anchors.centerIn: parent
                        icon: "monitor"
                        size: 22 * root.uiScale
                        color: Theme.selected
                    }
                }

                ColumnLayout {
                    spacing: 2 * root.uiScale
                    Text {
                        text: SystemInfo.osName
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 16 * root.uiScale
                        font.bold: true
                    }
                    Text {
                        text: "Up " + SystemInfo.uptime + " · " + root.displayList.length + " processes"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 11 * root.uiScale
                        opacity: 0.55
                    }
                }
            }

            CircularGauge {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 80 * root.uiScale
                Layout.preferredHeight: 80 * root.uiScale
                value: SystemStatsService.cpuUsage
                mainText: Math.round(SystemStatsService.cpuUsage * 100) + "%"
                subText: "CPU"
                progressColor: SystemStatsService.cpuUsage > 0.8 ? Theme.color1 : Theme.selected
                showSideText: false
            }

            CircularGauge {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 80 * root.uiScale
                Layout.preferredHeight: 80 * root.uiScale
                value: SystemStatsService.ramUsage
                mainText: SystemStatsService.ramUsedText
                subText: "Memory"
                progressColor: Theme.color4
                showSideText: false
            }

            Item {
                Layout.preferredWidth: 28 * root.uiScale
            }
        }

        // ── Search + filter ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10 * root.uiScale

            SearchBar {
                Layout.fillWidth: true
                placeholderText: "Search processes..."
                uiScale: root.uiScale
                text: root.searchQuery
                onTextChanged: root.searchQuery = text
            }

            RowLayout {
                spacing: 6 * root.uiScale
                Repeater {
                    model: [
                        {
                            key: "all",
                            label: "All"
                        },
                        {
                            key: "user",
                            label: "User"
                        },
                        {
                            key: "system",
                            label: "System"
                        },
                    ]
                    NavTile {
                        implicitWidth: 74 * root.uiScale
                        icon: ""
                        label: modelData.label
                        isActive: root.filterCategory === modelData.key
                        uiScale: root.uiScale
                        onTapped: root.filterCategory = modelData.key
                    }
                }
            }
        }

        // ── Table header ─────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * root.uiScale

            Text {
                Layout.fillWidth: true
                text: "Name"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11 * root.uiScale
                opacity: 0.5
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sortBy("name")
                }
            }
            RowLayout {
                Layout.preferredWidth: 70 * root.uiScale
                spacing: 2 * root.uiScale
                Text {
                    text: "CPU"
                    color: root.sortKey === "cpuPercent" ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    opacity: root.sortKey === "cpuPercent" ? 1.0 : 0.5
                }
                LucideIcon {
                    visible: root.sortKey === "cpuPercent"
                    icon: root.sortDescending ? "chevron-down" : "chevron-up"
                    size: 11 * root.uiScale
                    color: Theme.selected
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sortBy("cpuPercent")
                }
            }
            RowLayout {
                Layout.preferredWidth: 90 * root.uiScale
                spacing: 2 * root.uiScale
                Text {
                    text: "Memory"
                    color: root.sortKey === "memMb" ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    font.bold: root.sortKey === "memMb"
                    opacity: root.sortKey === "memMb" ? 1.0 : 0.5
                }
                LucideIcon {
                    visible: root.sortKey === "memMb"
                    icon: root.sortDescending ? "chevron-down" : "chevron-up"
                    size: 11 * root.uiScale
                    color: Theme.selected
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sortBy("memMb")
                }
            }
            Text {
                Layout.preferredWidth: 44 * root.uiScale
                text: "PID"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11 * root.uiScale
                opacity: 0.5
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sortBy("pid")
                }
            }
            Item {
                Layout.preferredWidth: 20 * root.uiScale
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // ── Process list ─────────────────────────────────────────
        ListView {
            id: processListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.displayList
            spacing: 2 * root.uiScale
            ScrollBar.vertical: CustomScrollBar {
                uiScale: root.uiScale
            }
            HoverHandler {
                id: listHoverHandler
            }

            delegate: Rectangle {
                id: row
                readonly property bool isHovered: rowHover.hovered
                readonly property bool isExpanded: !!root.expandedGroups[modelData.name]
                readonly property bool hasMultiple: modelData.count > 1

                width: ListView.view.width
                height: (40 * root.uiScale) + (isExpanded && hasMultiple ? modelData.count * (26 * root.uiScale) : 0)
                radius: 8 * root.uiScale
                color: isHovered ? Theme.backgroundAlt : "transparent"
                clip: true
                Behavior on height {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                readonly property string iconName: DesktopEntryService.lookup(modelData.name)?.icon ?? ""

                ColumnLayout {
                    anchors {
                        fill: parent
                        leftMargin: 8 * root.uiScale
                        rightMargin: 8 * root.uiScale
                        topMargin: 2 * root.uiScale
                    }
                    spacing: 2 * root.uiScale

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38 * root.uiScale
                        spacing: 8 * root.uiScale

                        Item {
                            width: 20 * root.uiScale
                            height: 20 * root.uiScale
                            Image {
                                id: procIcon
                                anchors.fill: parent
                                source: row.iconName !== "" ? DesktopEntryService.resolveIconPath(row.iconName) : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            LucideIcon {
                                anchors.centerIn: parent
                                icon: "cpu"
                                size: 14 * root.uiScale
                                color: Theme.foreground
                                opacity: 0.4
                                visible: procIcon.status !== Image.Ready
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: modelData.name
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12 * root.uiScale
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.preferredWidth: 70 * root.uiScale
                            text: modelData.cpuPercent.toFixed(1) + "%"
                            color: modelData.cpuPercent > 50 ? Theme.color1 : Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12 * root.uiScale
                        }
                        Text {
                            Layout.preferredWidth: 90 * root.uiScale
                            text: modelData.memMb >= 1024 ? (modelData.memMb / 1024).toFixed(1) + " GB" : modelData.memMb.toFixed(1) + " MB"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12 * root.uiScale
                            font.bold: true
                        }
                        Text {
                            Layout.preferredWidth: 44 * root.uiScale
                            text: row.hasMultiple ? ("×" + modelData.count) : modelData.pid.toString()
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12 * root.uiScale
                            opacity: 0.6
                        }
                        IconButton {
                            size: 20 * root.uiScale
                            iconSize: 13 * root.uiScale
                            icon: row.isExpanded ? "chevron-up" : "chevron-down"
                            visible: row.hasMultiple
                            normalColor: "transparent"
                            onTapped: root.toggleExpanded(modelData.name)
                        }
                    }

                    Repeater {
                        model: (row.isExpanded && row.hasMultiple) ? modelData.children : []

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24 * root.uiScale
                            Layout.leftMargin: 28 * root.uiScale
                            spacing: 8 * root.uiScale

                            Text {
                                Layout.fillWidth: true
                                text: "PID " + modelData.pid
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 11 * root.uiScale
                                opacity: 0.6
                            }
                            Text {
                                Layout.preferredWidth: 70 * root.uiScale
                                text: modelData.cpuPercent.toFixed(1) + "%"
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 11 * root.uiScale
                                opacity: 0.6
                            }
                            Text {
                                Layout.preferredWidth: 90 * root.uiScale
                                text: modelData.memMb.toFixed(1) + " MB"
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 11 * root.uiScale
                                opacity: 0.6
                            }
                        }
                    }
                }

                HoverHandler {
                    id: rowHover
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.displayList.length === 0
                text: "No matching processes"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13 * root.uiScale
                opacity: 0.4
            }
        }
    }

    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        icon: "x"
        size: 28 * root.uiScale
        iconSize: 13 * root.uiScale
        radius: Theme.radius
        normalColor: Theme.backgroundAlt
        hoverColor: Theme.color1
        tooltipText: "Close"
        onTapped: ShellState.closeResumableComponent()
    }
}
