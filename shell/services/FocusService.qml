pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    // Durations are adjustable now — these are just the starting
    // defaults, not fixed constants.
    property int focusDuration: 25 * 60   // seconds
    property int breakDuration: 5 * 60

    property string mode: "focus"   // "focus" | "break" — selects which counter below is active

    property int focusRemaining: focusDuration
    property int breakRemaining: breakDuration

    readonly property int remaining: mode === "focus" ? focusRemaining : breakRemaining
    readonly property int totalDuration: mode === "focus" ? focusDuration : breakDuration
    readonly property real progress: 1 - (remaining / totalDuration)

    // Adjustment step depends on mode — 5 min increments for focus
    // sessions, 1 min for shorter breaks.
    readonly property int stepSeconds: mode === "focus" ? 5 * 60 : 1 * 60

    property bool running: false

    property Timer _tick: Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.mode === "focus") {
                if (root.focusRemaining > 0)
                    root.focusRemaining--;
                else
                    root._completeSession();
            } else {
                if (root.breakRemaining > 0)
                    root.breakRemaining--;
                else
                    root._completeSession();
            }
        }
    }

    function _clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }

    function _completeSession() {
        root.running = false;
        if (root.mode === "focus") {
            InternalNotificationService.send("Focus session complete", "Time for a break!", "dialog-information");
            root.focusRemaining = root.focusDuration;
            root.mode = "break";
        } else {
            InternalNotificationService.send("Break's over", "Ready to focus again?", "dialog-information");
            root.breakRemaining = root.breakDuration;
            root.mode = "focus";
        }
    }

    function start() {
        root.running = true;
    }
    function pause() {
        root.running = false;
    }
    function toggle() {
        root.running = !root.running;
    }

    function reset() {
        root.running = false;
        if (root.mode === "focus")
            root.focusRemaining = root.focusDuration;
        else
            root.breakRemaining = root.breakDuration;
    }

    function switchMode(newMode) {
        if (newMode === root.mode)
            return;
        root.running = false;
        root.mode = newMode;
    }

    // Adjusts the CURRENT mode's duration by one step, clamped to
    // sensible bounds (focus: 5–120 min, break: 1–30 min). Changing
    // duration resets that mode's remaining time to the new full length
    // — adjusting mid-session doesn't have a clean "partial" meaning,
    // so we just restart that mode's countdown at the new duration.
    function increaseDuration() {
        _adjustDuration(root.stepSeconds);
    }
    function decreaseDuration() {
        _adjustDuration(-root.stepSeconds);
    }

    function _adjustDuration(delta) {
        root.running = false;
        if (root.mode === "focus") {
            root.focusDuration = _clamp(root.focusDuration + delta, 5 * 60, 120 * 60);
            root.focusRemaining = root.focusDuration;
        } else {
            root.breakDuration = _clamp(root.breakDuration + delta, 1 * 60, 30 * 60);
            root.breakRemaining = root.breakDuration;
        }
    }

    function formatTime() {
        const m = Math.floor(root.remaining / 60);
        const s = root.remaining % 60;
        return `${m}:${s.toString().padStart(2, "0")}`;
    }

    function formatDuration() {
        return Math.round(root.totalDuration / 60) + " min";
    }
}
