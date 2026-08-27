import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    // The two fixed pieces that make up this tab's height — matches
    // "Row size + scroll box size" exactly: the header's own height
    // (45, same number the header RowLayout below already uses via
    // Layout.preferredHeight) plus a deliberate target height for the
    // notification list. The list is a clipped, scrollable ListView —
    // it doesn't have (and doesn't need) a "natural" content height,
    // so this is a real design decision, not a measurement.
    readonly property real headerHeight: 45 * uiScale
    readonly property real listTargetHeight: 300 * uiScale
    readonly property real contentMargin: Math.max(15, 25 * uiScale)
    readonly property real contentSpacing: Math.max(10, 15 * uiScale)

    readonly property real cardHeight: Math.max(75, 85 * uiScale)
    readonly property real fontSizeBody: Math.max(11, 14 * uiScale)
    readonly property real fontSizeTitle: Math.max(12, 14 * uiScale)
    readonly property real iconSize: Math.max(50, 40 * uiScale)

    // No implicitWidth — this tab doesn't need an opinion on the
    // drawer's width (same reasoning as Overview.qml). implicitHeight
    // IS needed (tabsLoader depends on it) — composed bottom-up from
    // the fixed constants above, never from root's own live size (see
    // the historical note this used to carry: binding a scale factor
    // to root.height while implicitHeight is itself derived FROM that
    // scale factor is self-referential and collapses toward 0 the
    // moment implicitHeight is momentarily unresolved. uiScale here
    // comes from Theme.scaleFor(QsWindow.window?.screen) — the
    // physical monitor, not this component's own live layout size —
    // so that loop can't happen.)
    implicitHeight: headerHeight + contentSpacing + listTargetHeight + contentMargin * 2

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.contentMargin
        spacing: root.contentSpacing

        // ── Header ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight

            RowLayout {
                spacing: 10 * root.uiScale

                Text {
                    text: "Notifications"
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(18, 22 * root.uiScale)
                }
                Rectangle {
                    color: Theme.selected
                    height: 22 * root.uiScale
                    opacity: 0.9
                    radius: Theme.radius
                    visible: NotificationService.notifications.length > 0
                    width: Math.max(22 * root.uiScale, notifCountText.implicitWidth + (12 * root.uiScale))

                    Text {
                        id: notifCountText
                        anchors.centerIn: parent
                        text: NotificationService.notifications.length
                        color: Theme.background
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 14 * root.uiScale
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // ── DND toggle ────────────────────────────────────────
            IconButton {
                icon: Icons.getDndIcon(NotificationService.dndEnabled)
                size: 40 * root.uiScale
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                isActive: NotificationService.dndEnabled
                activeSolid: true
                dimWhenIdle: false
                onTapped: NotificationService.toggleDnd()
            }

            // ── Clear all ─────────────────────────────────────────
            IconButton {
                icon: "trash"
                size: 40 * root.uiScale
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.color1
                fixedIconColor: Theme.color1
                dimWhenIdle: false
                visible: NotificationService.notifications.length > 0
                onTapped: NotificationService.clearAll()
            }
        }

        // ── Content ───────────────────────────────────────────────
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                opacity: 0.4
                spacing: 12 * root.uiScale
                visible: NotificationService.notifications.length === 0

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: Icons.getDndIcon(NotificationService.dndEnabled)
                    size: 54 * root.uiScale
                    color: Theme.foreground
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: NotificationService.dndEnabled ? "Do Not Disturb is on" : "No new notifications"
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 14 * root.uiScale
                }
            }

            // Notification list
            ListView {
                id: notifListView
                anchors.fill: parent
                clip: true
                spacing: 10 * root.uiScale
                model: NotificationService.notifications
                visible: NotificationService.notifications.length > 0

                ScrollBar.vertical: CustomScrollBar {
                    uiScale: root.uiScale
                }

                add: Transition {
                    Anim {
                        properties: "opacity,scale"
                        from: 0
                        to: 1
                        type: Anim.DefaultEffects
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 250
                        easing.type: Easing.OutBack
                    }
                }
                remove: Transition {
                    Anim {
                        properties: "opacity,scale"
                        to: 0
                        type: Anim.DefaultEffects
                    }
                }

                delegate: NotificationCard {
                    required property var modelData
                    required property int index

                    width: notifListView.width
                    notif: modelData
                    uiScale: root.uiScale
                    cardHeight: root.cardHeight
                    iconSize: root.iconSize
                    fontSizeTitle: root.fontSizeTitle
                    fontSizeBody: root.fontSizeBody
                    onCloseRequested: NotificationService.close(index)
                }
            }
        }
    }
}
