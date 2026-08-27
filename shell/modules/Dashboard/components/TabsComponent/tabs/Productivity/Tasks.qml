import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    anchors.fill: parent
    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    // Deliberate, fixed — NOT the ListView's natural contentHeight.
    // Scaled by uiScale so the reserved space stays resolution-
    // appropriate; still fixed regardless of task count (list scrolls
    // internally via clip: true).
    property real listTargetHeight: 300 * uiScale

    property string filter: "active"
    property var filteredTasks: []

    function _updateFilteredTasks() {
        filteredTasks = root.filter === "active" ? TasksService.tasks.filter(t => !t.done) : TasksService.tasks.filter(t => t.done);
    }

    onFilterChanged: _updateFilteredTasks()
    Component.onCompleted: _updateFilteredTasks()

    Connections {
        target: TasksService
        function onTasksChanged() {
            root._updateFilteredTasks();
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 10 * root.uiScale

        // ── Add task input ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 40 * root.uiScale
            radius: Theme.radius
            color: Theme.backgroundAlt
            border.width: 1
            border.color: input.activeFocus ? Theme.selected : Theme.borderColor
            Behavior on border.color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12 * root.uiScale
                    rightMargin: 8 * root.uiScale
                }
                spacing: 8 * root.uiScale

                LucideIcon {
                    icon: "plus"
                    size: 14 * root.uiScale
                    color: Theme.foreground
                    opacity: 0.5
                }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                    clip: true
                    selectByMouse: true

                    Keys.onReturnPressed: {
                        TasksService.addTask(text);
                        text = "";
                    }
                    HoverHandler {
                        cursorShape: Qt.IBeamCursor
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add a task..."
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                        opacity: 0.35
                        visible: !input.text && !input.activeFocus
                    }
                }

                IconButton {
                    icon: "arrow-right"
                    size: 26 * root.uiScale
                    iconSize: 13 * root.uiScale
                    radius: Theme.radius
                    hoverColor: Theme.selected
                    activeColor: Theme.selected
                    enabled: input.text.trim() !== ""
                    onTapped: {
                        TasksService.addTask(input.text);
                        input.text = "";
                    }
                }
            }
        }

        // ── Active / Completed toggle ──────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * root.uiScale

            Repeater {
                model: [
                    {
                        key: "active",
                        icon: "circle-dashed",
                        label: "Active",
                        count: TasksService.remainingCount
                    },
                    {
                        key: "completed",
                        icon: "check-check",
                        label: "Completed",
                        count: TasksService.completedCount
                    },
                ]

                NavTile {
                    Layout.fillWidth: true
                    icon: modelData.icon
                    uiScale: root.uiScale
                    label: modelData.label + " (" + modelData.count + ")"
                    isActive: root.filter === modelData.key
                    onTapped: root.filter = modelData.key
                }
            }
        }

        // ── Task list ─────────────────────────────────────────────
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: root.listTargetHeight
            visible: root.filteredTasks.length > 0
            model: root.filteredTasks
            spacing: 4 * root.uiScale
            clip: true

            delegate: Rectangle {
                id: row
                readonly property bool isHovered: rowHover.hovered

                width: ListView.view.width
                height: 40 * root.uiScale
                radius: Theme.radius
                color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.1) : Theme.backgroundAlt

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10 * root.uiScale
                        rightMargin: 6 * root.uiScale
                    }
                    spacing: 10 * root.uiScale

                    Rectangle {
                        id: checkbox
                        width: 20 * root.uiScale
                        height: 20 * root.uiScale
                        radius: Theme.radius
                        color: modelData.done ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.9) : "transparent"
                        border.width: 1.5
                        border.color: modelData.done ? Theme.selected : Theme.borderColor
                        Behavior on color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }
                        Behavior on border.color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: "check"
                            size: 12 * root.uiScale
                            color: Theme.background
                            visible: modelData.done
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: TasksService.toggleTask(modelData.id)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.text
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13 * root.uiScale
                        font.strikeout: modelData.done
                        opacity: modelData.done ? 0.4 : 1.0
                        elide: Text.ElideRight
                        Behavior on opacity {
                            Anim {
                                type: Anim.FastEffects
                            }
                        }
                    }

                    IconButton {
                        icon: "x"
                        size: 24 * root.uiScale
                        iconSize: 12 * root.uiScale
                        radius: Theme.radius
                        hoverColor: Theme.color1
                        activeColor: Theme.color1
                        idleOpacity: 0.35
                        onTapped: TasksService.removeTask(modelData.id)
                    }
                }

                HoverHandler {
                    id: rowHover
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: root.listTargetHeight
            visible: root.filteredTasks.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8 * root.uiScale

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: root.filter === "active" ? "list-checks" : "check-check"
                    size: 32 * root.uiScale
                    color: Theme.foreground
                    opacity: 0.35
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.filter === "active" ? "No active tasks" : "No completed tasks"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                    opacity: 0.5
                }
            }
        }

        // ── Footer — clear completed, only relevant on that tab ────
        RowLayout {
            Layout.fillWidth: true
            visible: root.filter === "completed" && TasksService.completedCount > 0
            spacing: 8 * root.uiScale

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "trash-2"
                size: 26 * root.uiScale
                iconSize: 12 * root.uiScale
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.color1
                activeColor: Theme.color1
                tooltipText: "Clear completed"
                onTapped: TasksService.clearCompleted()
            }
        }
    }
}
