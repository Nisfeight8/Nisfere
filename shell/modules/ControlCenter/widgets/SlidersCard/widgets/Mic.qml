import QtQuick
import qs.services
import qs.core

SliderRow {
    activeIcon: "mic"
    mutedIcon: "mic-off"

    isMuteable: true
    isMuted: AudioService.sourceMuted
    value: AudioService.sourceVolume

    onToggleMuteClicked: AudioService.toggleSourceMute()
    onLiveValueMoved: newValue => AudioService.setSourceVolume(newValue)
}
