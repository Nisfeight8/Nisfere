import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "containers"
import "images"
import "volumes"

Rectangle {
    id: root
    property real uiScale: 1.0
    focus: true
    // Fixed size — standalone top-level Dashboard component, no
    // floor/ceiling system protecting it. Scaled by uiScale so this
    // panel gets proportionally more room on higher-res screens.
    anchors.fill: parent
    implicitWidth: 820 * uiScale
    implicitHeight: 600 * uiScale

    property int currentTab: 0

    property bool imagesLoaded: false
    property bool volumesLoaded: false
    Keys.onEscapePressed: ShellState.closeDashboard()

    onCurrentTabChanged: {
        if (currentTab === 1)
            imagesLoaded = true;
        if (currentTab === 2)
            volumesLoaded = true;
    }

    color: "transparent"

    Component.onCompleted: DockerService.requestDockerStats()

    Timer {
        id: dockerRefreshTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: DockerService.requestDockerStats()
    }
    Component.onDestruction: dockerRefreshTimer.stop()

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 10 * root.uiScale

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28 * root.uiScale

            Item {
                Layout.fillWidth: true
            }

            IconButton {
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60 * root.uiScale
            border.color: Theme.borderColor
            border.width: Theme.widgetBorderWidth
            radius: Theme.radius
            color: Theme.backgroundAlt

            NavTabs {
                id: dockerTabs
                anchors.fill: parent
                anchors.margins: 5 * root.uiScale
                spacing: 10 * root.uiScale
                currentIndex: root.currentTab
                onTabClicked: function (tabIndex) {
                    root.currentTab = tabIndex;
                }
                tabModel: [
                    {
                        title: "Containers",
                        icon: "box"
                    },
                    {
                        title: "Images",
                        icon: "layers"
                    },
                    {
                        title: "Volumes",
                        icon: "database"
                    }
                ]
            }
        }

        StackLayout {
            id: mainContent
            Layout.fillHeight: true
            Layout.fillWidth: true
            currentIndex: root.currentTab

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: true
                sourceComponent: Component {
                    ContainersComponent {
                        uiScale: root.uiScale
                    }
                }
            }

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: imagesLoaded
                sourceComponent: Component {
                    ImagesWidget {
                        // uiScale: root.uiScale
                    }
                }
            }

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: volumesLoaded
                sourceComponent: Component {
                    VolumesWidget {
                        // uiScale: root.uiScale
                    }
                }
            }
        }
    }
}
