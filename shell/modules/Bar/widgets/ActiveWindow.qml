import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

import qs.core
import qs.services

BarWidget {
    id: root

    readonly property string screenName: QsWindow.window?.screen?.name ?? ""
    readonly property var activeWin: HyprlandData.activeWindowForScreen(screenName)

    readonly property bool hasWindow: activeWin !== null
    readonly property string windowClass: (hasWindow && activeWin.lastIpcObject.class) ? activeWin.lastIpcObject.class : ""
    readonly property string windowTitle: hasWindow ? activeWin.title : "Desktop"
    readonly property string iconName: hasWindow && windowClass !== "" ? Icons.getAppIcon(windowClass) : Icons.getAppIcon("desktop")
    useGradient: true

    readonly property bool isHovered: winHover.hovered
    property bool popupOpen: false
    property bool popupContentHovered: false
    readonly property bool anyHovered: winHover.hovered || root.popupContentHovered

    property bool captureActive: false

    naturalContentWidth: iconText.implicitWidth + root.contentRow.spacing + Math.min(titleText.implicitWidth, 400)

    onPopupOpenChanged: {
        if (popupOpen) {
            captureStopTimer.stop();
            captureActive = true;
        } else {
            captureStopTimer.restart();
        }
    }

    Timer {
        id: captureStopTimer
        interval: AnimTokens.durationDefaultSpatial + 50
        onTriggered: root.captureActive = false
    }

    onAnyHoveredChanged: {
        if (anyHovered) {
            closeTimer.stop();
            popupOpen = true;
        }
    }

    Timer {
        id: closeTimer
        interval: 150
        running: !root.anyHovered && root.popupOpen
        onTriggered: root.popupOpen = false
    }

    Text {
        id: iconText
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: root.iconSize
        text: root.iconName
    }
    Text {
        id: titleText
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: root.fontSize
        elide: Text.ElideRight

        // Rendered/live width — CAN safely reference contentRow.width here
        // (the actual, possibly-shrunk layout width) since this property
        // is one-directional: it reads from contentRow but nothing reads
        // back from titleText.width into naturalContentWidth above.
        width: root._isConstrained ? Math.max(20, root.contentRow.width - iconText.implicitWidth - root.contentRow.spacing) : Math.min(titleText.implicitWidth, 400)

        text: root.windowTitle
    }

    HoverHandler {
        id: winHover
        parent: root
        cursorShape: Qt.PointingHandCursor
    }

    BarPopup {
        id: winPopup

        showPopup: root.popupOpen
        targetItem: root

        ColumnLayout {
            spacing: 10 * winPopup.uiScale

            HoverHandler {                
                enabled: root.popupOpen
                onHoveredChanged: root.popupContentHovered = hovered
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 17 * winPopup.uiScale
                text: root.hasWindow ? root.windowClass : "System"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 320 * winPopup.uiScale
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12 * winPopup.uiScale
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.8
                text: root.hasWindow ? root.windowTitle : "You are viewing the Desktop."
                wrapMode: Text.Wrap
            }
            ScreencopyView {
                id: captureView
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8 * winPopup.uiScale
                captureSource: root.captureActive ? root.activeWin.wayland : null
                constraintSize: Qt.size(320 * winPopup.uiScale, 200 * winPopup.uiScale)
                live: true
                visible: false
            }
            OpacityMask {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: captureView.height
                Layout.preferredWidth: captureView.width
                source: captureView
                visible: root.hasWindow && captureView.hasContent

                maskSource: Rectangle {
                    height: captureView.height
                    radius: Theme.radius
                    width: captureView.width
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.selected
                font.family: Theme.fontName
                font.pixelSize: 32 * winPopup.uiScale
                text: root.iconName
                visible: !root.hasWindow
            }
        }
    }
}
