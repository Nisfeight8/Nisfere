import QtQuick
import qs.services
import qs.core

SliderRow {
    activeIcon: Icons.getVolumeIcon(AudioService.volume, AudioService.muted)

    isMuteable: true
    isMuted: AudioService.muted
    mutedIcon: "volume-x"
    value: AudioService.volume

    onToggleMuteClicked: AudioService.toggleMute()
    onLiveValueMoved: newValue => AudioService.setVolume(newValue)
}
