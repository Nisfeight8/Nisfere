import QtQuick

import qs.core
import qs.services

ControlButton {
    iconText: isActive ? "moon-star" : "sun"
    isActive: NightLightService.isActive
    subtitle: isActive ? "Active" : "Disabled"
    title: "Night Light"

    onClicked: NightLightService.toggle()
}
