pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Persists the user's chosen avatar/profile picture path — read by
// Locker and SystemDrawer, written from a FileDialog in Settings.
// Same FileView+JsonAdapter pattern as SshUsageService/GitUsageService/
// DockerUsageService: a plain JSON cache file, no daemon involvement —
// this is pure "remember one string across restarts", no server-side
// work to justify routing it through the daemon.
Singleton {
    id: root

    readonly property string avatarPath: _adapter.avatarPath
    readonly property bool hasAvatar: avatarPath !== ""

    // Ensures ~/.cache/nisfere exists — same pattern already used for
    // Screenshots/Recordings output dirs (ScreenshotService's/
    // ScreenRecordService's own _mkdirProc).
    property Process _mkdirProc: Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.cache/nisfere"]
        running: true
    }

    property FileView _fileView: FileView {
        path: Quickshell.env("HOME") + "/.cache/nisfere/avatar.json"
        watchChanges: true
        onFileChanged: reload()
        // File doesn't exist yet on first run — write the (empty)
        // default adapter to create it, instead of erroring out.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: _adapter
            property string avatarPath: ""
        }
    }

    // path should be a plain filesystem path — see setAvatarFromUrl
    // for converting a FileDialog's file:// URL first. Stored and read
    // back exactly as given; QML's Image.source happily accepts either
    // a plain path or a file:// URL, so both forms work for DISPLAY
    // either way — this function itself doesn't care which you pass.
    function setAvatar(path) {
        _adapter.avatarPath = path;
        _fileView.writeAdapter();
    }

    // Convenience for FileDialog.selectedFile, which is a URL (e.g.
    // "file:///home/user/Pictures/me.png"), not a plain string —
    // strips the scheme down to a plain filesystem path before
    // storing, so anything reading avatarPath later that needs a REAL
    // path (e.g. a bash command, unlike Image.source which accepts the
    // URL form as-is) gets a consistently plain path regardless of how
    // it was originally set.
    function setAvatarFromUrl(url) {
        setAvatar(url.toString().replace(/^file:\/\//, ""));
    }

    function clearAvatar() {
        setAvatar("");
    }
}
