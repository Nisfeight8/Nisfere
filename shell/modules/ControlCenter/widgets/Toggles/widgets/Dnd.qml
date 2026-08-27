import QtQuick

import qs.core
import qs.services

ControlButton {
    iconText: Icons.getDndIcon(isActive)
    isActive: NotificationService.dndEnabled
    subtitle: isActive ? "On mute" : "Active"
    title: "DND"

    onClicked: NotificationService.toggleDnd()
}
