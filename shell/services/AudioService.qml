pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire
import Quickshell

Singleton {
    id: root

    readonly property bool muted: !!sink?.audio?.muted
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0.0
    readonly property real volume: sink?.audio?.volume ?? 0.0

    function setSourceVolume(newVolume) {
        if (source && source.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0.0, Math.min(1.0, newVolume));
        }
    }
    function setVolume(newVolume) {
        if (sink && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0.0, Math.min(1.0, newVolume));
        }
    }
    function toggleMute() {
        if (sink && sink.audio) {
            sink.audio.muted = !sink.audio.muted;
        }
    }
    function toggleSourceMute() {
        if (source && source.audio) {
            source.audio.muted = !source.audio.muted;
        }
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
