pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    property Connections _playerWatcher: Connections {
        function onValuesChanged() {
            if (root.selectedIndex >= root.list.length) {
                root.selectedIndex = Math.max(0, root.list.length - 1);
            }
        }

        ignoreUnknownSignals: true
        target: Mpris.players
    }
    property Timer _posTimer: Timer {
        interval: 1000
        repeat: true
        running: root.hasPlayer

        onTriggered: {
            if (root.active)
                root.active.positionChanged();
        }
    }

    readonly property real position: active?.position ?? 0
    readonly property real progress: (active && length > 0) ? (position / length) : 0
    property int selectedIndex: 0
    property string title: active && active.trackTitle ? active.trackTitle : "No media playing"
    readonly property MprisPlayer active: (list.length > 0 && selectedIndex < list.length) ? list[selectedIndex] : (list.length > 0 ? list[0] : null)
    property string albumArt: getArtUrl(active)
    property string artist: active && active.trackArtist ? active.trackArtist : ""
    property bool hasPlayer: active !== null
    property IpcHandler ipcHandler: IpcHandler {
        function list(): string {
            return root.list.map(p => root.getIdentity(p)).join("\n");
        }
        function next(): void {
            root.next();
        }
        function pause(): void {
            if (root.active?.canPause)
                root.active.pause();
        }
        function play(): void {
            if (root.active?.canPlay)
                root.active.play();
        }
        function playPause(): void {
            root.togglePlayPause();
        }
        function previous(): void {
            root.previous();
        }
        function stop(): void {
            root.stop();
        }

        target: "mpris"
    }

    property bool isPlaying: active && active.playbackState === MprisPlaybackState.Playing
    readonly property real length: (active && active.length > 0) ? active.length : 1
    readonly property list<MprisPlayer> list: Mpris.players.values

    function getArtUrl(player) {
        if (!player)
            return "";
        if (player.trackArtUrl)
            return player.trackArtUrl;

        const url = player.metadata["xesam:url"] ?? "";
        if (url.startsWith("https://www.youtube.com/watch")) {
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
        }
        return "";
    }
    function getIdentity(player) {
        return player ? player.identity : "";
    }
    function next() {
        if (active && active.canGoNext)
            active.next();
    }
    function previous() {
        if (active && active.canGoPrevious)
            active.previous();
    }
    function seek(targetPosition) {
        if (active && active.canSeek && length > 0)
            active.position = targetPosition;
    }
    function selectPlayer(index) {
        if (index >= 0 && index < root.list.length) {
            root.selectedIndex = index;
        }
    }
    function stop() {
        if (active)
            active.stop();
    }
    function togglePlayPause() {
        if (active && active.canTogglePlaying)
            active.togglePlaying();
    }
}
