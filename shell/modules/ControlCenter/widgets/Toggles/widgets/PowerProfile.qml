import QtQuick
import qs.core
import qs.services
import Quickshell.Services.UPower

ControlButton {
    hasMore: false
    iconText: PowerProfileService.profileIcon
    isActive: PowerProfileService.currentProfile === PowerProfile.Performance
    subtitle: PowerProfileService.isDegraded ? PowerProfileService.degradationText : PowerProfileService.profileName
    title: "Energy"

    onClicked: PowerProfileService.cycleProfile()
}
