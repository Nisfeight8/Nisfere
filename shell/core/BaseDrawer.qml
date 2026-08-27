import QtQuick
import qs.core
import qs.services
import "drawer"

Item {
    id: root

    // Which screen this drawer instance belongs to — set explicitly by
    // whoever instantiates it (ScreenBorder.qml), same pattern as
    // triggerHovered below. Not every BaseDrawer user needs this
    // (OSD/NotificationPopup's `opened` has nothing to do with
    // activeScreenName at all), so it's just a plain fact exposed
    // here, unused unless a specific drawer's `opened` expression
    // references it.
    property var screen: null
    readonly property string screenName: screen?.name ?? ""

    // Externally, callers set openedRequest (simple — "what makes me
    // want to open", e.g. `openedRequest: ShellState.dashboardOpened`)
    // — the actual `opened` below combines that with a screen check,
    // but ONLY when a screen was actually provided. OSD/NotificationPopup
    // never set `screen:` (stays null), so their `opened` is just
    // `openedRequest` unchanged — this centralizes the multi-screen
    // gating in one place instead of repeating it in every drawer file
    // that does care about it (Dashboard/ControlCenter/SystemDrawer).
    property bool openedRequest: false
    readonly property bool opened: screen !== null ? (openedRequest && ShellState.activeScreenName === screenName) : openedRequest

    // ── Public API ───────────────────────────────────────────────────
    property int edge: Qt.LeftEdge
    property bool cornerMode: false
    property bool sidePanelMode: false
    property int cornerSecondaryEdge: Qt.TopEdge
    property real edgeMargin: Theme.screenBorderSize

    property real minPanelWidth: 0
    property real minPanelHeight: 0
    property real maxPanelWidth: -1
    property real maxPanelHeight: -1

    property real screenOffset: 0
    property bool asynchronousLoad: true
    property bool preload: false

    property Component contentComponent

    property bool _wasHovered: false

    property bool triggerHovered: false
    property bool toggleOnHover: true

    signal closeRequest

    readonly property bool isHorizontal: geometry.isHorizontal
    readonly property real panelWidth: geometry.panelWidth
    readonly property real panelHeight: geometry.panelHeight
    readonly property alias panelItem: panelItem

    // Was root's own property, driven by two inline Anim blocks — now
    // sourced from the shared OpenCloseOffset engine (see
    // core/anim/OpenCloseOffset.qml). Kept as a readonly alias so any
    // existing external `.offset` reads keep working unchanged.
    readonly property alias offset: motion.offset

    onOpenedChanged: {
        if (opened)
            _wasHovered = root.triggerHovered || contentHover.hovered;
        else
            _wasHovered = false;
    }

    onTriggerHoveredChanged: {
        if (triggerHovered && root.opened)
            root._wasHovered = true;
    }

    OpenCloseOffset {
        id: motion
        opened: root.opened
    }

    DrawerGeometry {
        id: geometry
        edge: root.edge
        cornerMode: root.cornerMode
        sidePanelMode: root.sidePanelMode
        cornerSecondaryEdge: root.cornerSecondaryEdge
        edgeMargin: root.edgeMargin

        minPanelWidth: root.minPanelWidth
        minPanelHeight: root.minPanelHeight
        maxPanelWidth: root.maxPanelWidth
        maxPanelHeight: root.maxPanelHeight

        contentWidth: contentHost.contentImplicitWidth
        contentHeight: contentHost.contentImplicitHeight

        offset: root.offset
        screenOffset: root.screenOffset
    }

    anchors.fill: parent

    Timer {
        id: autoCloseTimer
        interval: 150
        running: root.toggleOnHover && root.opened && root._wasHovered && !root.triggerHovered && !contentHover.hovered
        onTriggered: root.closeRequest()
    }

    Item {
        id: panelItem
        height: {
            if (root.isHorizontal && !root.cornerMode) {
                if (root.sidePanelMode) {
                    return parent.height - root.screenOffset - root.edgeMargin;
                }
                return parent.height;
            }
            return root.panelHeight;
        }
        // height: (root.isHorizontal && !root.cornerMode) ? parent.height : root.panelHeight
        width: (!root.isHorizontal && !root.cornerMode) ? root.panelWidth : root.panelWidth

        clip: true
        visible: root.offset < 1

        x: {
            if (root.edge === Qt.LeftEdge)
                return root.edgeMargin - geometry.slideDistanceH;
            if (root.edge === Qt.RightEdge)
                return parent.width - width - root.edgeMargin + geometry.slideDistanceH;

            if (root.cornerMode) {
                if (root.cornerSecondaryEdge === Qt.LeftEdge)
                    return root.edgeMargin;
                if (root.cornerSecondaryEdge === Qt.RightEdge)
                    return parent.width - width - root.edgeMargin;
            }

            return (parent.width - width) / 2;
        }

        y: {
            if (root.edge === Qt.TopEdge)
                return root.screenOffset - geometry.slideDistanceV;
            if (root.edge === Qt.BottomEdge)
                return parent.height - height - root.edgeMargin + geometry.slideDistanceV;

            if (root.cornerMode) {
                if (root.cornerSecondaryEdge === Qt.TopEdge)
                    return root.screenOffset;
                if (root.cornerSecondaryEdge === Qt.BottomEdge)
                    return parent.height - height - root.edgeMargin;
            }
            if (root.sidePanelMode) {
                return root.screenOffset;
            }
            return (parent.height - height) / 2;
        }

        HoverHandler {
            id: contentHover
            onHoveredChanged: {
                if (hovered && root.opened)
                    root._wasHovered = true;
            }
        }

        DrawerBackground {
            anchors.fill: parent
            edge: root.edge
            cornerMode: root.cornerMode
            sidePanelMode: root.sidePanelMode
            cornerSecondaryEdge: root.cornerSecondaryEdge
            opened: root.opened
            bgColor: Theme.background
        }

        DrawerContentHost {
            id: contentHost
            anchors.fill: parent
            contentComponent: root.contentComponent
            opened: root.opened
            preload: root.preload
            asynchronousLoad: root.asynchronousLoad

            marginTop: geometry._mTop
            marginBottom: geometry._mBottom
            marginLeft: geometry._mLeft
            marginRight: geometry._mRight
        }
    }
}
