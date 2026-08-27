pragma Singleton
import Quickshell

// System power actions — reboot/suspend/poweroff via systemd, lock via
// loginctl, logout via hyprshutdown. Quickshell.execDetached is
// fire-and-forget (no stdout/lifecycle to track, unlike Process), which
// is all any of these need — the shell doesn't stick around to see the
// result anyway. Adjust the commands below if your setup needs
// something else.
Singleton {
    id: root

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function logout() {
        Quickshell.execDetached(["hyprshutdown"]);
    }
}
