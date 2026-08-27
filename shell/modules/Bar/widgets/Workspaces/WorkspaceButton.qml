import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

Item {
    id: wsItem

    required property var modelData   // HyprlandWorkspace

    readonly property bool isFocused: modelData.focused
    readonly property var myWindows: modelData.toplevels.values
    readonly property int windowsCount: myWindows.length

    // Local ratios, same style as BarWidget's iconSize/fontSize —
    // this delegate has no BarWidget ancestor to inherit those from
    // (it's instantiated directly by Workspaces.qml's Repeater), so
    // it derives its own from Theme.barHeight for consistency.
    readonly property real _refHeight: Theme.scaledBarHeight(QsWindow.window?.screen) - 15
    readonly property real glyphSizeFocused: Math.max(16, _refHeight * 0.75)
    readonly property real glyphSizeUnfocused: Math.max(12, _refHeight * 0.5)
    readonly property real appIconSizeFocused: Math.max(12, _refHeight * 0.5)
    readonly property real appIconSizeUnfocused: Math.max(10, _refHeight * 0.44)

    implicitWidth: content.implicitWidth + 16
    implicitHeight: widgetHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: wsItem.isFocused ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : hover.hovered ? Theme.backgroundAlt : "transparent"
        border.width: wsItem.isFocused ? 1 : 0
        border.color: Theme.selected
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 6

        // ── Workspace indicator glyph ─────────────────────────────
        Text {
            color: wsItem.isFocused ? Theme.selected : Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: wsItem.isFocused ? wsItem.glyphSizeFocused : wsItem.glyphSizeUnfocused
            text: {
                if (wsItem.isFocused)
                    return "󰮯";
                else
                    return "󰊠";
                return "";
            }
            Behavior on font.pixelSize {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutBack
                }
            }
        }

        // ── App icons — real icons, always visible ────────────────
        Row {
            visible: wsItem.windowsCount > 0
            spacing: 5

            Repeater {
                model: wsItem.myWindows

                delegate: Text {
                    id: iconWrap
                    required property var modelData

                    readonly property string appClass: {
                        if (modelData.wayland && modelData.wayland.appId)
                            return modelData.wayland.appId;
                        if (modelData.lastIpcObject && modelData.lastIpcObject.class)
                            return modelData.lastIpcObject.class;
                        return "";
                    }

                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: wsItem.isFocused ? wsItem.appIconSizeFocused : wsItem.appIconSizeUnfocused
                    text: Icons.getAppIcon(appClass)
                }
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: wsItem.modelData.activate()
    }
}
