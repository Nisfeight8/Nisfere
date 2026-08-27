pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "tabs"
import "tabs/Overview"
import "tabs/Productivity"
import "tabs/Notifications"

// The Dashboard's Tabs page — visible whenever
// ShellState.dashboardActiveComponent === "tabs". Self-contained: owns
// the NavTabs row + the AnimLoader that switches between the 5 info
// tabs. No knowledge of search/panels at all — that's entirely
// SearchComponent's job now.
Item {
    id: root
    property real uiScale: 1.0

    // Floors the panel's implicit size so switching between tabs with
    // very different natural sizes (Overview vs. Productivity vs.
    // Weather, ...) doesn't visibly resize the whole Dashboard panel
    // every time — this implicitWidth/Height is what ultimately
    // reaches DrawerGeometry's contentWidth/contentHeight via
    // DashboardContent, so clamping it here fixes the jump for every
    // tab at once instead of patching each tab individually.
    // Tune these to whichever tab is your natural "biggest common
    // case" — going bigger than that just adds empty space under/
    // beside smaller tabs (worth an explicit Layout.alignment on
    // mainColumn's content if that empty space looks awkward).
    // Scaled by uiScale so the floor itself stays resolution-
    // appropriate — without this, a 1080p-tuned floor would be too
    // small on a 4K screen and risk overlapping content.
    property real minContentWidth: 750 * root.uiScale
    property real minContentHeight: 380 * root.uiScale

    implicitWidth: Math.max(mainColumn.implicitWidth, minContentWidth)
    implicitHeight: Math.max(mainColumn.implicitHeight, minContentHeight)

    Component {
        id: overviewComp
        Overview {
            uiScale: root.uiScale
        }
    }
    Component {
        id: mediaComp
        Media {
            uiScale: root.uiScale
        }
    }
    Component {
        id: weatherComp
        Weather {
            uiScale: root.uiScale
        }
    }
    Component {
        id: notificationsComp
        Notifications {
            uiScale: root.uiScale
        }
    }
    Component {
        id: productivityComp
        Productivity {
            uiScale: root.uiScale
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 15 * root.uiScale

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            NavTabs {
                id: navTabs
                Layout.fillWidth: true
                height: 30 * root.uiScale
                uiScale: root.uiScale
                currentIndex: ShellState.dashboardTabsCurrentTab
                onTabClicked: index => ShellState.dashboardTabsCurrentTab = index
                tabModel: [
                    {
                        icon: "layout-dashboard",
                        title: "Overview"
                    },
                    {
                        icon: "music",
                        title: "Media"
                    },
                    {
                        icon: "sun",
                        title: "Weather"
                    },
                    {
                        icon: "bell",
                        title: "Alerts"
                    },
                    {
                        icon: "brain",
                        title: "Productivity"
                    },
                ]
            }
        }

        AnimLoader {
            id: tabsLoader
            Layout.fillWidth: true
            
            sourceComp: {
                switch (ShellState.dashboardTabsCurrentTab) {
                case 0:
                    return overviewComp;
                case 1:
                    return mediaComp;
                case 2:
                    return weatherComp;
                case 3:
                    return notificationsComp;
                case 4:
                    return productivityComp;
                default:
                    return overviewComp;
                }
            }
        }
    }
}
