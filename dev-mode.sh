#!/usr/bin/env bash
#
# dev-mode.sh — toggle ~/.config/nisfere between "installed" (plain
# copies, daemon managed by systemd via socket activation) and "dev"
# (symlinked straight to this repo checkout, daemon stopped so you run
# it yourself and see live output).
#
# Run install.sh once first — this only toggles daemon/shell/
# templates/themes/templates.json, it doesn't touch packages, the
# systemd unit files themselves, or dots/{qtengine,gtk-*,systemd}
# (those rarely change once set up).
#
# Usage:
#   ./dev-mode.sh         auto-detect current state, switch to the other
#   ./dev-mode.sh on      force dev mode
#   ./dev-mode.sh off     force normal (installed) mode

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NISFERE_DIR="$HOME/.config/nisfere"

# What gets toggled — same set install.sh installs from the repo root
# (not the dots/ ones, those stay as-is either way).
ITEMS=(daemon shell templates themes templates.json)

log()  { echo -e "\033[1;34m[nisfere-dev]\033[0m $*"; }
warn() { echo -e "\033[1;33m[nisfere-dev]\033[0m $*"; }
err()  { echo -e "\033[1;31m[nisfere-dev]\033[0m $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    err "Don't run this as root — it operates on your own \$HOME."
    exit 1
fi

if [[ ! -d "$NISFERE_DIR" ]]; then
    err "$NISFERE_DIR doesn't exist yet — run install.sh first."
    exit 1
fi

is_dev_mode() {
    # Dev mode = daemon is a symlink pointing at THIS repo's daemon/.
    [[ -L "$NISFERE_DIR/daemon" ]] || return 1
    [[ "$(readlink -f "$NISFERE_DIR/daemon")" == "$(readlink -f "$REPO_DIR/daemon")" ]]
}

switch_on() {
    log "Switching to DEV mode..."

    log "Killing any running quickshell instance..."
    pkill -x quickshell 2>/dev/null || true

    # Stop BOTH units, not just the .service. With socket activation,
    # nisfere-daemon.socket is what actually owns/binds
    # /tmp/nisfere-shell.sock — if it's left running while you `python3
    # main.py` manually, your manual run and systemd's own listening
    # socket end up fighting over the same filesystem path. Stopping
    # the socket too means systemd fully releases it, so your manual
    # run's own fallback (self-managed, no LISTEN_FDS) socket creation
    # in socket_manager.py has a clean path to bind to.
    log "Stopping nisfere-daemon.socket/.service (you'll run the daemon manually instead)..."
    systemctl --user stop nisfere-daemon.socket nisfere-daemon.service 2>/dev/null || true

    for name in "${ITEMS[@]}"; do
        dst="$NISFERE_DIR/$name"
        rm -rf "$dst"
        ln -s "$REPO_DIR/$name" "$dst"
        log "  $name -> symlinked to repo"
    done

    # ~/.config/quickshell already symlinks to $NISFERE_DIR/shell (set
    # up once by install.sh) — now that shell itself points into the
    # repo, it resolves through automatically, nothing else to do.

    echo
    log "Dev mode ON. Edits in $REPO_DIR are live. Run these yourself, in separate terminals, so you can see output/errors:"
    echo "    cd $NISFERE_DIR/daemon && python3 main.py"
    echo "    quickshell"
    echo
    warn "Note: nisfere-daemon.socket is stopped for the whole session now, not just this moment — if you log out/in (or reboot) while still in dev mode, it WILL come back via graphical-session.target on the next session start and could conflict with a manual run you start again afterward. Run '$0 off' before ending your session if you're not sure."
}

switch_off() {
    log "Switching back to NORMAL (installed) mode..."

    log "Killing any running (dev) quickshell instance..."
    pkill -x quickshell 2>/dev/null || true

    warn "If you still have a manual 'python3 main.py' running in another terminal from dev mode, Ctrl+C it now before continuing — it's holding /tmp/nisfere-shell.sock itself, and starting nisfere-daemon.socket below will fail to bind while that's still alive."

    for name in "${ITEMS[@]}"; do
        dst="$NISFERE_DIR/$name"
        rm -rf "$dst"
        cp -r "$REPO_DIR/$name" "$dst"
        log "  $name -> copied from repo"
    done
    # Stray logs shouldn't ship in the fresh copy.
    rm -f "$NISFERE_DIR/daemon/output.log" "$NISFERE_DIR/daemon/output2.log"

    # Restart the SOCKET, not the service directly. Directly starting/
    # restarting nisfere-daemon.service here would spawn it without
    # the LISTEN_FDS/LISTEN_PID env vars systemd only sets when a unit
    # is triggered THROUGH its socket — the daemon would just fall
    # back to self-managed socket creation (see socket_manager.py),
    # sidestepping socket activation entirely and putting you right
    # back to the original race this whole setup was meant to fix.
    log "Restarting nisfere-daemon.socket..."
    systemctl --user daemon-reload
    systemctl --user restart nisfere-daemon.socket

    echo
    log "Normal mode ON. Daemon socket is listening again via systemd; the daemon service itself starts automatically on first connection. Start quickshell yourself now, or it'll come up on your next Hyprland login via exec-once:"
    echo "    quickshell"
}

case "${1:-}" in
on)
    switch_on
    ;;
off)
    switch_off
    ;;
"")
    if is_dev_mode; then
        log "Currently in dev mode -> switching to normal."
        switch_off
    else
        log "Currently in normal mode -> switching to dev."
        switch_on
    fi
    ;;
*)
    err "Usage: $0 [on|off]"
    exit 1
    ;;
esac