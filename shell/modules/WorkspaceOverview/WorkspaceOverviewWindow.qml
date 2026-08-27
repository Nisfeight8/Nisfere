import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.services

// One window's tile inside the overview.
Item {
    id: root

    required property var windowData
    required property var toplevel
    property real tileScale: 1
    property real xOffset: 0
    property real yOffset: 0
    property bool previewsEnabled: true
    property bool live: false
    property bool dragActive: false

    readonly property real initX: Math.max((windowData?.at?.[0] ?? 0), 0) * tileScale + xOffset
    readonly property real initY: Math.max((windowData?.at?.[1] ?? 0), 0) * tileScale + yOffset
    // Renamed from tileWidth/tileHeight — those names collided
    // confusingly with panel.tileWidth/tileHeight in Overview.qml,
    // which is a DIFFERENT thing (the whole workspace box's size, not
    // this specific window's scaled-down size). This is deliberately
    // NOT derived from parent.width/height: parent is the workspace
    // tile, and multiple windows with different real sizes can share
    // one workspace — using parent's size here would make every window
    // in a workspace render the same size, losing the whole point of
    // the overview (showing each window's actual relative size/position
    // within its workspace).
    readonly property real scaledWidth: Math.max(1, (windowData?.size?.[0] ?? 100)) * tileScale
    readonly property real scaledHeight: Math.max(1, (windowData?.size?.[1] ?? 100)) * tileScale

    Drag.active: root.dragActive
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    signal pressedAt(real globalX, real globalY)
    signal released
    signal draggedTo(real globalX, real globalY)

    x: initX
    y: initY
    width: scaledWidth
    height: scaledHeight
    scale: dragActive ? 1.05 : 1.0
    opacity: dragActive ? 0.85 : 1.0
    transformOrigin: Item.Center
    z: dragActive ? 1000 : 1
    clip: !dragActive

    // Was raw NumberAnimation(150, OutCubic) — same "quick, pure
    // decelerate, no overshoot" category as Anim.FastToggle (already
    // used for exactly this elsewhere, e.g. WallpapersPanel's zoom),
    // just for consistency with scale/opacity/border.color below,
    // which already correctly use Anim.
    Behavior on x {
        enabled: !root.dragActive
        Anim {
            type: Anim.FastToggle
        }
    }
    Behavior on y {
        enabled: !root.dragActive
        Anim {
            type: Anim.FastToggle
        }
    }
    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }
    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    readonly property string _iconName: {
        const cls = root.windowData?.class ?? "";
        return DesktopEntryService.iconFor(cls, "");
    }

    readonly property real _cornerRadius: Theme.radius

    // ClippingRectangle (Quickshell.Widgets, needs Qt 6.7+) properly
    // clips ANY content to its rounded shape automatically — replaces
    // the whole manual OpacityMask + separate mask Rectangle setup we
    // had before. That setup's mask was sized to match the (deliberately
    // oversized, for cover-fit) preview instead of the card's own visible
    // bounds, which is why rounding silently failed whenever a tile's
    // preview needed oversizing (reported as "no radius with 2 windows
    // in a workspace" — really about aspect-ratio mismatch, not window
    // count). ClippingRectangle clips its own bounds regardless of how
    // its children are sized internally, so that whole bug class can't
    // happen anymore.
    ClippingRectangle {
        id: card
        anchors.fill: parent
        radius: root._cornerRadius
        color: Theme.backgroundAlt
        border.width: Theme.widgetBorderWidth
        border.color: root.dragActive ? Theme.selected : dragArea.containsMouse ? Theme.foreground : Theme.borderColor
        Behavior on border.color {
            AnimColor {
                type: Anim.FastEffects
            }
        }

        ScreencopyView {
            id: preview
            anchors.centerIn: parent
            captureSource: (root.previewsEnabled && root.toplevel && ShellState.overviewOpen) ? root.toplevel : null
            live: root.live

            // Delayed via Qt.callLater — calling captureFrame() immediately
            // in onCompleted fires before the recording context is fully
            // established (ScreencopyView logs "Cannot capture frame, as
            // no recording context is ready"). Pushing it to the next
            // event loop tick gives it time to finish setting up first.
            Component.onCompleted: if (!live)
                Qt.callLater(() => captureFrame())

            readonly property real srcAspect: {
                const w = root.windowData?.size?.[0] ?? 0;
                const h = root.windowData?.size?.[1] ?? 0;
                return (w > 0 && h > 0) ? (w / h) : 1;
            }

            width: Math.max(parent.width, parent.height * srcAspect)
            height: Math.max(parent.height, parent.width / srcAspect)
        }

        Image {
            id: appIcon
            anchors.centerIn: parent
            z: 10
            visible: root._iconName !== ""
            source: root._iconName !== "" ? Quickshell.iconPath(root._iconName) : ""
            sourceSize: Qt.size(Math.min(parent.width, parent.height) * 0.4, Math.min(parent.width, parent.height) * 0.4)
            asynchronous: true
        }

        LucideIcon {
            anchors.centerIn: parent
            z: 10
            visible: !appIcon.visible
            icon: "app-window"
            size: Math.min(parent.width, parent.height) * 0.35
            color: Theme.foreground
            opacity: 0.6
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 4
            visible: parent.height > 40
            text: root.windowData?.title ?? ""
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 11
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Deliberately NOT migrated to DragHandler/TapHandler — this is
    // intricate custom drag-gesture tracking (manual threshold via
    // Qt.styleHints.startDragDistance, global-coordinate signals for
    // reparenting into dragLayer, distinguishing left-drag from
    // left-tap-to-focus from middle-tap-to-close). Working correctly
    // as-is; too much risk of subtly changing behavior for not enough
    // benefit right now. Say the word if you want it revisited.
    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: dragArea.dragStarted ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property point pressPos: Qt.point(0, 0)
        property point pressItemGlobalPos: Qt.point(0, 0)
        property bool dragStarted: false

        onPressed: mouse => {
            pressPos = mapToItem(null, mouse.x, mouse.y);
            dragStarted = false;
        }

        onPositionChanged: mouse => {
            if (!pressed)
                return;

            const current = mapToItem(null, mouse.x, mouse.y);

            if (!dragStarted) {
                const dx = current.x - pressPos.x;
                const dy = current.y - pressPos.y;
                if (Math.hypot(dx, dy) < Qt.styleHints.startDragDistance)
                    return;

                dragStarted = true;
                root.dragActive = true;
                pressItemGlobalPos = root.mapToItem(null, 0, 0);
                root.pressedAt(current.x, current.y);
            }

            root.x = pressItemGlobalPos.x + (current.x - pressPos.x);
            root.y = pressItemGlobalPos.y + (current.y - pressPos.y);
            root.draggedTo(current.x, current.y);
        }

        onReleased: mouse => {
            if (dragStarted) {
                dragStarted = false;
                root.dragActive = false;
                root.released();
            } else if (mouse.button === Qt.LeftButton) {
                ShellState.overviewOpen = false;
                Hyprland.dispatch(`hl.dsp.focus({ window = "address:${root.windowData?.address}" })`);
            } else if (mouse.button === Qt.MiddleButton) {
                Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${root.windowData?.address}" })`);
            }
        }

        StyledToolTip {
            visible: dragArea.containsMouse && !root.dragActive
            text: `${root.windowData?.title ?? "Unknown"}\n[${root.windowData?.class ?? "?"}]`
        }
    }
}
