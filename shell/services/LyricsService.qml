pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Fetches synced (.lrc-format) lyrics for whatever MediaService says is
// currently loaded, and exposes the line that should be showing right
// now based on playback position.
//
// v1 scope (deliberately simpler than caelestia's C++ Lyrics.cpp,
// which this was modeled on): local .lrc folder -> LRCLIB -> NetEase,
// same fallback order as caelestia. No on-disk caching, no candidate
// picker, no persisted per-track sync offset — all addable later if
// wanted, but not needed for showing lyrics on the wallpaper.
//
// Unlike AudioVisualizer/cava, this does NOT need visibility gating —
// fetching lyrics is a small one-shot network/file request per track
// change, not a continuous process, so it just runs whenever the
// track changes regardless of whether anything is currently showing
// them on screen.
Singleton {
    id: root

    // ── Config ───────────────────────────────────────────────────
    // Local .lrc folder to check before hitting LRCLIB (recursively
    // searched, matched by filename containing both artist+title,
    // same convention as caelestia). Leave "" to skip local lookup
    // entirely and go straight to LRCLIB.
    property string lyricsDir: ""

    // Manual sync adjustment in seconds — positive delays the lyrics,
    // negative shows them earlier. Not persisted per-track (v1).
    property real offset: 0

    // ── State ────────────────────────────────────────────────────
    property var lines: []          // [{ time: <seconds>, text: "..." }, ...] sorted by time
    property bool hasLyrics: false
    property bool loading: false
    property string error: ""
    property string backend: ""     // "local" | "lrclib" | "netease" | ""

    // ── Track-change trigger ─────────────────────────────────────
    readonly property string trackKey: MediaService.artist + " - " + MediaService.title

    property Timer _debounce: Timer {
        interval: 200
        repeat: false
        onTriggered: root._doLoad()
    }

    onTrackKeyChanged: root._debounce.restart()
    Component.onCompleted: root._debounce.restart()

    // ── Current-line lookup ──────────────────────────────────────
    // Binary search, same idea as caelestia's indexForTime — MediaService
    // only pushes position updates roughly once a second (see its own
    // _posTimer), which is plenty granular for line-level lyric sync.
    readonly property int currentLineIndex: {
        if (root.lines.length === 0)
            return -1;
        const target = MediaService.position - root.offset;
        let lo = 0;
        let hi = root.lines.length;
        while (lo < hi) {
            const mid = (lo + hi) >> 1;
            if (root.lines[mid].time <= target)
                lo = mid + 1;
            else
                hi = mid;
        }
        return lo - 1;
    }
    readonly property string currentLineText: (root.currentLineIndex >= 0 && root.currentLineIndex < root.lines.length) ? root.lines[root.currentLineIndex].text : ""

    // ── Loading pipeline ─────────────────────────────────────────
    function _resetState() {
        root.lines = [];
        root.hasLyrics = false;
        root.error = "";
        root.backend = "";
    }

    function _doLoad() {
        root._resetState();

        if (MediaService.title === "" || MediaService.title === "No media playing" || MediaService.artist === "")
            return;

        root.loading = true;

        if (root.lyricsDir !== "")
            root._tryLocal();
        else
            root._tryLrclib();
    }

    // ── Local .lrc lookup (find filename match, then read it) ────
    property Process _findProc: Process {
        id: findProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._onFindFinished(text)
        }
    }
    property Process _catProc: Process {
        id: catProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._onLocalFileRead(text)
        }
    }

    function _tryLocal() {
        findProc.command = ["find", root.lyricsDir, "-iname", "*.lrc"];
        findProc.running = true;
    }

    function _onFindFinished(text) {
        const paths = text.split("\n").map(s => s.trim()).filter(s => s !== "");
        const artistLower = MediaService.artist.toLowerCase();
        const titleLower = MediaService.title.toLowerCase();
        const match = paths.find(p => {
            const name = p.toLowerCase();
            return name.includes(artistLower) && name.includes(titleLower);
        });

        if (match) {
            catProc.command = ["cat", match];
            catProc.running = true;
        } else {
            root._tryLrclib();
        }
    }

    function _onLocalFileRead(text) {
        const parsed = root._parseLrc(text);
        if (parsed.length === 0) {
            // Found a filename match but couldn't parse actual synced
            // lines out of it — fall through to LRCLIB instead of
            // just giving up.
            root._tryLrclib();
            return;
        }
        root.lines = parsed;
        root.hasLyrics = true;
        root.backend = "local";
        root.loading = false;
    }

    // ── LRCLIB ────────────────────────────────────────────────────
    function _tryLrclib() {
        const xhr = new XMLHttpRequest();
        let url = "https://lrclib.net/api/get?track_name=" + encodeURIComponent(MediaService.title) + "&artist_name=" + encodeURIComponent(MediaService.artist);
        if (MediaService.length > 1)
            url += "&duration=" + Math.round(MediaService.length);

        xhr.open("GET", url);
        xhr.timeout = 8000;

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                root._tryNetEase();
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                const synced = data.syncedLyrics || "";

                if (synced === "") {
                    root._tryNetEase();
                    return;
                }

                const parsed = root._parseLrc(synced);
                if (parsed.length === 0) {
                    root._tryNetEase();
                    return;
                }

                root.lines = parsed;
                root.hasLyrics = true;
                root.backend = "lrclib";
                root.error = "";
                root.loading = false;
            } catch (e) {
                console.error("LyricsService: LRCLIB parse error:", e);
                root._tryNetEase();
            }
        };
        xhr.ontimeout = function () {
            root._tryNetEase();
        };
        xhr.onerror = function () {
            root._tryNetEase();
        };

        xhr.send();
    }

    // ── NetEase (2nd fallback) ─────────────────────────────────────
    // Public search + lyric endpoints, no auth token needed. Custom
    // User-Agent/Referer headers mirror caelestia's netEaseHeaders —
    // NetEase's API rejects requests that look too bare/scripted
    // without them.
    function _tryNetEase() {
        const xhr = new XMLHttpRequest();
        const q = encodeURIComponent(MediaService.title + " " + MediaService.artist);
        const url = "https://music.163.com/api/search/get?s=" + q + "&type=1&limit=5";
        
        xhr.open("GET", url);
        xhr.timeout = 8000;
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0");
        xhr.setRequestHeader("Referer", "https://music.163.com/");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                root._finishWithError("NetEase search failed");
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                const songs = (data.result && data.result.songs) || [];
                const artistLower = MediaService.artist.toLowerCase();

                let bestId = -1;
                for (const s of songs) {
                    const artists = s.artists || [];
                    if (artists.length === 0)
                        continue;
                    const sArtist = (artists[0].name || "").toLowerCase();
                    if (artistLower.includes(sArtist) || sArtist.includes(artistLower)) {
                        bestId = s.id;
                        break;
                    }
                }

                if (bestId < 0) {
                    root._finishWithError("No NetEase match found");
                    return;
                }

                root._fetchNetEaseLyricsById(bestId);
            } catch (e) {
                console.error("LyricsService: NetEase search parse error:", e);
                root._finishWithError("Invalid NetEase search response");
            }
        };
        xhr.ontimeout = function () {
            root._finishWithError("NetEase search timed out");
        };
        xhr.onerror = function () {
            root._finishWithError("NetEase search failed");
        };

        xhr.send();
    }

    function _fetchNetEaseLyricsById(id) {
        const xhr = new XMLHttpRequest();
        const url = "https://music.163.com/api/song/lyric?id=" + id + "&lv=1&kv=1&tv=-1";

        xhr.open("GET", url);
        xhr.timeout = 8000;
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0");
        xhr.setRequestHeader("Referer", "https://music.163.com/");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            root.loading = false;

            if (xhr.status !== 200) {
                root.error = "NetEase lyric request failed";
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                const lrc = (data.lrc && data.lrc.lyric) || "";

                if (lrc === "") {
                    root.error = "No NetEase lyrics found";
                    return;
                }

                const parsed = root._parseLrc(lrc);
                if (parsed.length === 0) {
                    root.error = "Could not parse NetEase lyrics";
                    return;
                }

                root.lines = parsed;
                root.hasLyrics = true;
                root.backend = "netease";
                root.error = "";
            } catch (e) {
                console.error("LyricsService: NetEase lyric parse error:", e);
                root.error = "Invalid NetEase lyric response";
            }
        };
        xhr.ontimeout = function () {
            root.loading = false;
            root.error = "NetEase lyric request timed out";
        };
        xhr.onerror = function () {
            root.loading = false;
            root.error = "NetEase lyric request failed";
        };

        xhr.send();
    }

    // Final "nothing worked" state — used once every backend in the
    // chain has been exhausted.
    function _finishWithError(message) {
        root.loading = false;
        root.error = message;
    }

    // ── .lrc parsing ──────────────────────────────────────────────
    // [mm:ss.xx]lyric text — supports multiple timestamps on one line
    // (rare but valid lrc). No credit-line filtering in v1 (caelestia
    // has some heuristics for that); add later if stray "Lyricist:"/
    // "Composer:" lines from certain sources turn out to be a problem
    // in practice.
    function _parseLrc(text) {
        const timeRegex = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
        const rawLines = text.split("\n");
        const result = [];

        for (const line of rawLines) {
            timeRegex.lastIndex = 0;
            const matches = [];
            let m;
            while ((m = timeRegex.exec(line)) !== null)
                matches.push(m);

            if (matches.length === 0)
                continue;

            const lyric = line.replace(timeRegex, "").trim();

            for (const match of matches) {
                const t = parseInt(match[1]) * 60 + parseFloat(match[2]);
                result.push({
                    time: t,
                    text: lyric
                });
            }
        }

        result.sort((a, b) => a.time - b.time);
        return result;
    }
}
