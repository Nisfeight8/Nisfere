import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"
import "../components"

Rectangle {
    id: root

    // Was missing entirely — CustomScrollView below already read
    // `root.uiScale`, but nothing here ever declared it, so that
    // binding silently resolved to undefined and nothing in this file
    // scaled with the rest of DockerManager at all.
    property real uiScale: 1.0

    property var expandedProjects: ({})

    // Object.entries + map instead of manual var/for key iteration —
    // same data, clearer. config_files defaults to [] (an array) now,
    // not "" (a string) — the daemon always sends it as a list (see
    // docker_service.py's _fetch_containers), so the old string
    // default was the wrong type for whatever eventually consumes it.
    readonly property var projectsArray: Object.entries(DockerService.composeProjects ?? {}).map(([name, p]) => ({
                name: name,
                working_dir: p.working_dir ?? "",
                config_files: p.config_files ?? [],
                containers: p.containers ?? []
            }))

    function isExpanded(name) {
        return expandedProjects.hasOwnProperty(name) ? expandedProjects[name] : true;
    }
    function toggleExpanded(name) {
        const copy = Object.assign({}, expandedProjects);
        copy[name] = !isExpanded(name);
        expandedProjects = copy;
    }

    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 6 * root.uiScale

        // 1. Header
        Rectangle {
            Layout.fillWidth: true
            border.color: Theme.borderColor
            border.width: 1
            color: Theme.backgroundAlt
            height: 54 * root.uiScale
            radius: Theme.radius - 2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14 * root.uiScale
                anchors.rightMargin: 12 * root.uiScale
                spacing: 10 * root.uiScale

                LucideIcon {
                    icon: "container"
                    size: 22 * root.uiScale
                    color: Theme.selected
                }
                Column {
                    spacing: 1 * root.uiScale

                    Text {
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 15 * root.uiScale
                        text: "Docker"
                    }
                    Text {
                        color: Theme.foregroundAlt
                        font.family: Theme.fontName
                        font.pixelSize: 10 * root.uiScale
                        text: root.projectsArray.length + " projects · " + DockerService.standaloneContainers.length + " standalone"
                    }
                }
                Item {
                    Layout.fillWidth: true
                }

                // Running / total badge
                Rectangle {
                    id: badge

                    property color bc: hasError ? Theme.color1 : DockerService.runningContainers > 0 ? Theme.color10 : Theme.foregroundAlt
                    property bool hasError: DockerService.errorMessage !== ""

                    border.color: Qt.rgba(bc.r, bc.g, bc.b, 0.45)
                    border.width: 1
                    color: Qt.rgba(bc.r, bc.g, bc.b, 0.12)
                    height: 28 * root.uiScale
                    radius: height / 2
                    width: badgeText.implicitWidth + 18 * root.uiScale

                    Text {
                        id: badgeText

                        anchors.centerIn: parent
                        color: badge.bc
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 11 * root.uiScale
                        text: badge.hasError ? "Error" : DockerService.runningContainers + "/" + DockerService.totalContainers + " running"
                    }
                }
            }
        }

        // 2. Error banner — shows either a structural/connection-level
        // issue (errorMessage, from the docker_stats payload itself)
        // or the most recent failed ACTION (lastActionError — e.g. a
        // stop/restart that failed), whichever is present.
        // lastActionError clears automatically on the next successful
        // docker_stats (every 3s via the refresh timer), so this is
        // self-clearing without needing an explicit dismiss button.
        Rectangle {
            Layout.fillWidth: true
            border.color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.40)
            border.width: 1
            color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.12)
            height: 30 * root.uiScale
            radius: 8 * root.uiScale
            visible: DockerService.errorMessage !== "" || DockerService.lastActionError !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12 * root.uiScale
                anchors.rightMargin: 12 * root.uiScale
                spacing: 6 * root.uiScale

                LucideIcon {
                    icon: "triangle-alert"
                    size: 13 * root.uiScale
                    color: Theme.color1
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.color1
                    elide: Text.ElideRight
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    text: DockerService.errorMessage !== "" ? DockerService.errorMessage : (DockerService.lastActionErrorAction + ": " + DockerService.lastActionError)
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        CustomScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            uiScale: root.uiScale

            Column {
                spacing: 6 * root.uiScale
                width: parent.width

                Repeater {
                    model: root.projectsArray

                    delegate: ProjectSection {
                        required property var modelData
                        uiScale: root.uiScale
                        isExpanded: root.isExpanded(proj.name)
                        proj: modelData

                        onToggleRequested: root.toggleExpanded(proj.name)
                    }
                }
                StandaloneSection {
                    uiScale: root.uiScale
                    containers: DockerService.standaloneContainers
                }
            }
        }
    }
}
