import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.core

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: overlay
        required property var modelData
        screen: modelData
        visible: AreaPickerService.active

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        property point startPt
        property point curPt
        property bool selecting: false

        Rectangle {
            anchors.fill: parent
            color: "#33000000"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            onPressed: mouse => {
                overlay.startPt = Qt.point(mouse.x, mouse.y);
                overlay.curPt = overlay.startPt;
                overlay.selecting = true;
            }
            onPositionChanged: mouse => {
                if (overlay.selecting)
                    overlay.curPt = Qt.point(mouse.x, mouse.y);
            }
            onReleased: {
                overlay.selecting = false;
                const localX = Math.min(overlay.startPt.x, overlay.curPt.x);
                const localY = Math.min(overlay.startPt.y, overlay.curPt.y);
                const w = Math.abs(overlay.curPt.x - overlay.startPt.x);
                const h = Math.abs(overlay.curPt.y - overlay.startPt.y);
                if (w < 2 || h < 2) {
                    AreaPickerService.cancel();
                    return;
                }
                AreaPickerService.finish(Screen.virtualX + localX, Screen.virtualY + localY, w, h);
            }
        }

        Rectangle {
            visible: overlay.selecting
            x: Math.min(overlay.startPt.x, overlay.curPt.x)
            y: Math.min(overlay.startPt.y, overlay.curPt.y)
            width: Math.abs(overlay.curPt.x - overlay.startPt.x)
            height: Math.abs(overlay.curPt.y - overlay.startPt.y)
            color: "#3388ccff"
            border.color: Theme.selected
            border.width: 1
        }

        Item {
            anchors.fill: parent
            focus: overlay.visible
            Keys.onEscapePressed: AreaPickerService.cancel()
        }
    }
}
