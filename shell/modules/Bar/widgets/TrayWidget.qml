import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.core

BarWidget {
    id: trayWidget

    property var activeMenuHandle: null

    useGradient: true
    visible: trayRepeater.count > 0

    Repeater {
        id: trayRepeater

        model: SystemTray.items

        delegate: Item {
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            width: 20

            readonly property bool isHovered: iconHover.hovered

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                smooth: true
                source: modelData.icon
                opacity: isHovered ? 0.7 : 1.0

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
            }

            HoverHandler {
                id: iconHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onTapped: (eventPoint, button) => {
                    if (button === Qt.LeftButton) {
                        modelData.activate();
                    } else if (button === Qt.MiddleButton) {
                        modelData.secondaryActivate();
                    } else if (button === Qt.RightButton) {
                        if (modelData.hasMenu) {
                            if (trayWidget.activeMenuHandle === modelData.menu) {
                                trayWidget.activeMenuHandle = null;
                            } else {
                                trayWidget.activeMenuHandle = modelData.menu;
                            }
                        }
                    }
                }
            }
            // WheelHandler proved unreliable in AudioWidget — same
            // fallback here: plain MouseArea just for wheel scroll,
            // acceptedButtons: Qt.NoButton so it never competes with
            // the TapHandler above for clicks.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: Qt.PointingHandCursor
                onWheel: wheel => {
                    const delta = wheel.angleDelta.y > 0 ? 1 : -1;
                    modelData.scroll(delta, false);
                }
            }
        }
    }
    QsMenuOpener {
        id: menuOpener

        menu: trayWidget.activeMenuHandle
    }
    BarPopup {
        id: customMenuPopup

        showPopup: trayWidget.activeMenuHandle !== null
        targetItem: trayWidget

        ListView {
            id: menuList
            // Was `width: 200` — a raw actual-size assignment on the
            // direct content of PopupContainer, which now wraps its
            // content in a WrapperItem (see PopupContainer.qml). Per
            // the Quickshell docs' own WrapperItem warning, the child
            // must expose implicitWidth/implicitHeight, never set its
            // own actual width/height directly — WrapperItem manages
            // that FOR it, based on implicit size. With a raw `width:`
            // here, implicitWidth stayed 0, so WrapperItem sized (and
            // overrode) this down to ~nothing, cutting off every
            // menu item's text. implicitWidth is the fix.
            implicitWidth: 200
            implicitHeight: contentHeight
            interactive: false
            model: menuOpener.children
            spacing: 4

            delegate: Rectangle {
                id: menuDelegate
                readonly property bool isHovered: itemHover.hovered

                color: modelData.isSeparator ? Theme.backgroundAlt : (isHovered ? Theme.backgroundAlt : "transparent")
                height: modelData.isSeparator ? 1 : 30
                radius: 6
                width: menuList.width

                Behavior on color {
                    AnimColor {
                        type: Anim.FastEffects
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8
                    visible: !modelData.isSeparator

                    Image {
                        Layout.preferredHeight: 16
                        Layout.preferredWidth: 16
                        opacity: modelData.icon !== "" ? 1 : 0
                        source: modelData.icon || ""
                    }
                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        elide: Text.ElideRight
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        text: modelData.text || ""
                    }
                }

                HoverHandler {
                    id: itemHover
                    enabled: !modelData.isSeparator
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    enabled: !modelData.isSeparator
                    onTapped: {
                        modelData.triggered();
                        trayWidget.activeMenuHandle = null;
                    }
                }
            }
        }
    }
}
