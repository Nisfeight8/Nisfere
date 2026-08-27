import QtQuick
import QtQuick.Layouts
import qs.core

// Reusable file-list section for GitManager.qml (Staged/Changes/
// Untracked) — was an inline `component` declaration inside
// GitManager.qml itself, but that syntax isn't supported/recognized
// here, so it's its own file instead, same convention as every other
// reusable sub-component in this shell.
ColumnLayout {
    id: section

    property real uiScale: 1.0
    property string title: ""
    property var files: []
    property string actionIcon: ""
    property string actionTooltip: ""
    property string sectionActionTooltip: ""
    signal fileAction(string file)
    signal sectionAction

    Layout.fillWidth: true
    spacing: 4 * uiScale
    visible: files.length > 0

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: section.title + " (" + section.files.length + ")"
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 12 * section.uiScale
            font.bold: true
            opacity: 0.6
        }
        IconButton {
            icon: "chevrons-" + (section.actionIcon === "plus" ? "up" : "down")
            size: 22 * section.uiScale
            iconSize: 12 * section.uiScale
            tooltipText: section.sectionActionTooltip
            normalColor: "transparent"
            hoverColor: Theme.selected
            onTapped: section.sectionAction()
        }
    }

    Repeater {
        model: section.files
        delegate: RowLayout {
            required property string modelData
            Layout.fillWidth: true
            spacing: 6 * section.uiScale

            Text {
                Layout.fillWidth: true
                text: modelData
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12 * section.uiScale
                elide: Text.ElideMiddle
            }
            IconButton {
                icon: section.actionIcon
                size: 22 * section.uiScale
                iconSize: 12 * section.uiScale
                tooltipText: section.actionTooltip
                normalColor: "transparent"
                hoverColor: Theme.selected
                onTapped: section.fileAction(modelData)
            }
        }
    }
}
