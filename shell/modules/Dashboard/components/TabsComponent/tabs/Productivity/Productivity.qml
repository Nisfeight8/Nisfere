
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    anchors.fill: parent

    implicitHeight: rowLayout.implicitHeight

    Component {
        id: tasksComp
        Tasks {
            uiScale: root.uiScale
        }
    }
    Component {
        id: focusComp
        FocusTimer {
            uiScale: root.uiScale
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 12 * root.uiScale

        SideMenu {
            id: sideMenu
            Layout.fillHeight: true
            // Capped at 35% of available row width so it never dominates on a
            // narrow screen, but floored at 140*uiScale so it never shrinks
            // below a legible minimum either — a percentage alone can shrink
            // indefinitely on a small enough screen, this stops it there and
            // lets the AnimLoader content area absorb any remaining squeeze
            // instead.
            Layout.preferredWidth: Math.max(140 * root.uiScale, Math.min(implicitWidth, rowLayout.width * 0.25))
            currentIndex: ShellState.dashboardTabsCurrentProductivityTab
            onTabClicked: index => ShellState.dashboardTabsCurrentProductivityTab = index
            uiScale: root.uiScale
            menuModel: [
                {
                    icon: "list-checks",
                    title: "Tasks"
                },
                {
                    icon: "timer",
                    title: "Focus"
                },
            ]
        }

        // Divider
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        AnimLoader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComp: ShellState.dashboardTabsCurrentProductivityTab === 0 ? tasksComp : focusComp
        }
    }
}
