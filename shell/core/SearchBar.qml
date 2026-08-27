import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholderText: "Search..."
    property bool showClearButton: true
    property real uiScale: 1.0

    signal accepted
    signal keyPressed(var event)

    height: 40 * uiScale
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
            icon: "search"
            size: 15 * root.uiScale
            color: Theme.foreground
            opacity: 0.5
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // I-beam (text) cursor, not the pointing-hand used for
            // clickable actions elsewhere — this is the standard OS
            // convention for a text-editable area. Scoped to just this
            // wrapper (the actual input + placeholder), so the search
            // icon and clear button on either side keep their own
            // appropriate cursors instead of also showing I-beam.
            HoverHandler {
                cursorShape: Qt.IBeamCursor
            }

            TextInput {
                id: input
                anchors.fill: parent
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 14 * root.uiScale
                clip: true
                selectByMouse: true
                verticalAlignment: TextInput.AlignVCenter

                Keys.onReturnPressed: root.accepted()
                Keys.onEnterPressed: root.accepted()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        return;
                    root.keyPressed(event);
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.placeholderText
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 14 * root.uiScale
                opacity: 0.35
                visible: input.text === ""
                elide: Text.ElideRight
                width: parent.width
            }
        }

        IconButton {
            visible: root.showClearButton && input.text !== ""
            icon: "x"
            size: 22 * root.uiScale
            iconSize: 12 * root.uiScale
            normalColor: "transparent"
            onTapped: input.text = ""
        }
    }
}
