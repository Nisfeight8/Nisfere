#!/usr/bin/env bash
#
# install.sh — Nisfere shell installer
#
# Installs: Hyprland config, qtengine, GTK settings (all from
# dots/), the daemon + Quickshell shell + templates/themes
# (~/.config/nisfere), all required packages (via yay), fonts,
# systemd --user socket-activated service for the daemon, XDG user
# dirs, and a first-run default theme apply.
#
# Run from the root of the nisfere repo (the folder containing
# daemon/, dots/, shell/, templates/, themes/, templates.json).
#
# Usage:
#   ./install.sh            normal (fresh) run — packages, dotfiles,
#                            prompts, the works.
#   ./install.sh --dry-run  print every command that WOULD run, touch
#                           nothing — safe to run on your real machine
#                           just to sanity-check paths/package list.
#   ./install.sh --update   for machines that already have nisfere
#                           installed — re-syncs daemon/shell/
#                           templates/themes from this checkout and
#                           restarts the daemon + Quickshell to pick
#                           up the change, but skips EVERYTHING that's
#                           one-time setup (packages, dotfiles, XDG
#                           dirs, sudoers/docker/SDDM prompts, the
#                           default-theme apply). Combine with
#                           --dry-run to preview an update too.
#
# For active development against a git checkout, use dev-mode.sh
# instead (switches ~/.config/nisfere between this install and a
# symlinked, live-editable copy of your repo) — run install.sh once
# to get everything else (packages, systemd units, dotfiles) in place.

set -euo pipefail

DRY_RUN=0
UPDATE_MODE=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --update) UPDATE_MODE=1 ;;
        *) ;;
    esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NISFERE_DIR="$HOME/.config/nisfere"

MAX_BACKUPS=3
LOG_FILE="/tmp/nisfere-install-$(date +%Y%m%d-%H%M%S).log"
: > "$LOG_FILE" 2>/dev/null || LOG_FILE="$(mktemp)"

STEP_NUM=0

log()  { echo -e "\033[1;34m[nisfere]\033[0m $*"; }
warn() { echo -e "\033[1;33m[nisfere]\033[0m $*"; }
err()  { echo -e "\033[1;31m[nisfere]\033[0m $*" >&2; }

# Numbered section header for the big, user-visible phases of the install.
# Purely cosmetic/orientation — doesn't gate any logic.
step() {
    STEP_NUM=$((STEP_NUM + 1))
    echo
    echo -e "\033[1;35m▸ $STEP_NUM.\033[0m \033[1m$*\033[0m"
    # Refresh sudo's cached credentials right here, in the foreground.
    # Cheap/instant if already valid; if it somehow lapsed, this prompts
    # visibly and normally instead of a later background step silently
    # failing (or worse) because sudo couldn't ask for a password it needed.
    [[ $DRY_RUN -eq 0 ]] && sudo -v
    return 0
}

print_logo() {
    [[ -t 1 ]] || return 0
    echo -e "\033[1;35m"
    cat <<'EOF'
 _  _ ___ ___ ___ ___ ___ ___ 
| \| |_ _/ __| __| __| _ \ __|
| .` || |\__ \ _|| _||   / _| 
|_|\_|___|___/_| |___|_|_\___|
EOF
    echo -e "\033[0m\033[2m  Hyprland shell — installer\033[0m"
    echo
}

run() {
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "\033[2m[dry-run]\033[0m $*"
    else
        "$@"
    fi
}

# Runs a noisy/slow command in the background, hides its output behind a
# spinner, and only ever shows that output if the command actually fails
# (tail of $LOG_FILE, plus the full path so it can be inspected after).
# Used for things like `yay -S`, `makepkg`, `git clone` — commands whose
# normal output is hundreds of lines that don't help the user follow along,
# but whose failure output is exactly what they need to debug.
# Runs a noisy/slow command in the background, hides its output behind a
# spinner, and only ever shows that output if the command actually fails
# (tail of $LOG_FILE, plus the full path so it can be inspected after).
# Used for things like `yay -S`, `makepkg`, `git clone` — commands whose
# normal output is hundreds of lines that don't help the user follow along,
# but whose failure output is exactly what they need to debug.
#
# IMPORTANT: stdin is closed (</dev/null) for the backgrounded command. If
# it ever needs interactive confirmation we haven't accounted for, it gets
# EOF and fails fast/visibly instead of hanging forever on a prompt that's
# buried in the log file where nobody can see or answer it.
spin() {
    local pid="$1" msg="$2"
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0 elapsed=0
    if [[ ! -t 1 ]]; then
        # Not an interactive terminal (piped/logged) — skip the animation
        # but still print something, so logs aren't silent while waiting.
        echo "... $msg"
        local status
        if wait "$pid"; then status=0; else status=$?; fi
        if [[ $status -eq 0 ]]; then
            echo "done: $msg"
        else
            echo "FAILED: $msg"
        fi
        return $status
    fi
    tput civis 2>/dev/null || true
    local start_s=$SECONDS hint_shown=0 cols
    cols=$(tput cols 2>/dev/null || echo 80)
    while kill -0 "$pid" 2>/dev/null; do
        local elapsed=$((SECONDS - start_s))
        if (( elapsed >= 20 && hint_shown == 0 )); then
            hint_shown=1
            # Print this once as a normal scrolling line — NOT part of the
            # repeatedly-overwritten spinner line, so a long path can never
            # cause the wrap-induced duplicate-line bug below.
            printf "\r\033[2K\033[2m  (still going — tail -f %s to watch)\033[0m\n" "$LOG_FILE"
        fi
        local line="${frames:$i:1} $msg"
        (( elapsed >= 20 )) && line="$line (${elapsed}s)"
        # Truncate to terminal width. Without this, a line longer than the
        # terminal wraps onto a second row; \r then returns to the start of
        # that WRAPPED row (not the true start of the printed line), so
        # each redraw appends a new line instead of overwriting — exactly
        # the runaway-scrolling bug seen with a long $LOG_FILE path baked
        # into every frame.
        if (( ${#line} >= cols )); then
            line="${line:0:$((cols > 1 ? cols - 1 : 1))}"
        fi
        printf "\r\033[2K%s" "$line"
        i=$(( (i + 1) % ${#frames} ))
        sleep 0.15
    done
    # `wait "$pid"` as a bare statement can trip `set -e` and kill the
    # whole script silently if the job's exit status handling is ever
    # unusual (e.g. sudo re-forking under a new session because it needed
    # a password). Wrapping it as an `if` condition exempts it from that.
    local status
    if wait "$pid"; then status=0; else status=$?; fi
    tput cnorm 2>/dev/null || true
    if [[ $status -eq 0 ]]; then
        printf "\r\033[2K\033[1;32m✓\033[0m %s\n" "$msg"
    else
        printf "\r\033[2K\033[1;31m✗\033[0m %s\n" "$msg"
    fi
    return $status
}

CURRENT_BG_PID=""
# On Ctrl+C, kill whatever's currently running quietly in the background
# instead of leaving an orphaned build/pacman process behind.
trap '[[ -n "$CURRENT_BG_PID" ]] && kill -TERM "$CURRENT_BG_PID" 2>/dev/null; echo; err "Interrupted."; exit 130' INT

run_quiet() {
    local msg="$1"; shift
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "\033[2m[dry-run]\033[0m $*"
        return 0
    fi
    {
        echo "=== $(date '+%H:%M:%S') — $msg ==="
        echo "+ $*"
    } >> "$LOG_FILE"
    "$@" </dev/null >> "$LOG_FILE" 2>&1 &
    local pid=$! status
    CURRENT_BG_PID="$pid"
    spin "$pid" "$msg"
    status=$?
    CURRENT_BG_PID=""
    if [[ $status -ne 0 ]]; then
        err "$msg — failed. Last 30 lines of log:"
        echo -e "\033[2m$(tail -n 30 "$LOG_FILE")\033[0m" >&2
        err "Full log: $LOG_FILE"
    fi
    return $status
}

prune_backups() {
    local dst="$1"
    local dir base
    dir="$(dirname "$dst")"
    base="$(basename "$dst")"

    local backups=()
    while IFS= read -r -d '' f; do
        backups+=("$f")
    done < <(find "$dir" -maxdepth 1 -name "${base}.bak-*" -print0 2>/dev/null | sort -z -r)

    if (( ${#backups[@]} > MAX_BACKUPS )); then
        local old
        for old in "${backups[@]:$MAX_BACKUPS}"; do
            run rm -rf "$old"
        done
    fi
}

copy_backed_up() {
    local src="$1"
    local dst="$2"

    if [[ -e "$dst" || -L "$dst" ]]; then
        warn "Existing $dst found — backing up to ${dst}.bak-$(date +%s)"
        run mv "$dst" "${dst}.bak-$(date +%s)"
        prune_backups "$dst"
    fi
    run mkdir -p "$(dirname "$dst")"
    run cp -r "$src" "$dst"
}

install_dotdir() {
    local name="$1"
    copy_backed_up "$REPO_DIR/dots/$name" "$HOME/.config/$name"
}

if [[ $EUID -eq 0 ]]; then
    err "Don't run this as root — it installs into your own \$HOME. Run as your normal user (it'll ask for sudo/yay password when needed)."
    exit 1
fi

print_logo

if [[ $DRY_RUN -eq 1 ]]; then
    warn "DRY RUN — no packages will be installed, no files written, nothing enabled. Just printing what would happen."
fi
if [[ $UPDATE_MODE -eq 1 ]]; then
    log "UPDATE MODE — skipping packages/dotfiles/prompts, only re-syncing daemon/shell/templates/themes and restarting the daemon + Quickshell."
    if [[ ! -d "$NISFERE_DIR" ]]; then
        err "--update given, but $NISFERE_DIR doesn't exist yet — run a normal (non --update) install first."
        exit 1
    fi
fi

if [[ $DRY_RUN -eq 0 ]]; then
    log "Full build/install logs are being written to $LOG_FILE (only shown here if a step fails)."
    log "Requesting sudo access up front, so it doesn't interrupt a step later..."
    sudo -v
    # Keep the sudo timestamp alive for the whole script so none of the
    # quiet/spinner steps below end up silently blocked on a password
    # prompt that's buried in $LOG_FILE instead of on screen.
    ( while true; do sudo -n true 2>/dev/null; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
    SUDO_KEEPALIVE_PID=$!
    trap '[[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
fi

if [[ $UPDATE_MODE -eq 0 ]]; then

if ! command -v yay >/dev/null 2>&1; then
    step "Installing yay (AUR helper)"
    log "Installing git + base-devel (build prerequisites)..."
    run sudo pacman -S --needed --noconfirm git base-devel
    tmp_yay="$(mktemp -d)"
    run_quiet "Cloning yay from the AUR" git clone https://aur.archlinux.org/yay.git "$tmp_yay/yay"
    # Same build/install split as qmltermwidget below: compile quietly in
    # the background (no privilege needed), install in the foreground
    # (needs sudo — must NOT be hidden behind closed stdin).
    run_quiet "Compiling yay" bash -c "cd '$tmp_yay/yay' && makepkg -s --noconfirm"
    log "Installing yay (uses sudo — visible here, not hidden)..."
    run bash -c "cd '$tmp_yay/yay' && sudo pacman -U --noconfirm \$(makepkg --packagelist)"
    rm -rf "$tmp_yay"
else
    log "yay already installed, skipping"
fi

PACKAGES=(
    hyprland
    hypridle
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-user-dirs
    polkit-kde-agent
    bluez
    bluez-utils
    networkmanager
    wl-clipboard
    trash-cli
    quickshell
    awww
    adw-gtk-theme
    papirus-icon-theme
    papirus-folders
    breeze
    qtengine
    bibata-cursor-theme
    ttf-noto-nerd
    noto-fonts
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
    nwg-look
    thunar
    thunar-volman
    thunar-archive-plugin
    xarchiver
    xfconf
    gvfs
    gvfs-mtp
    gvfs-gphoto2
    udisks2
    tumbler
    ffmpegthumbnailer
    zip
    unzip
    p7zip
    unrar
    alacritty
    bpytop
    zsh
    fastfetch
    cava
    power-profiles-daemon
    brightnessctl
    cliphist
    hyprpicker
    wlsunset
    hyprshutdown
    wf-recorder
    grim
    slurp
    jq
    pacman-contrib
    python-jinja
    python-psutil
    python-pillow
    python-numpy
)

step "Installing ${#PACKAGES[@]} packages via yay (this can take a few minutes on a fresh system)"
run_quiet "Installing packages (pacman + AUR)" yay -S --needed --noconfirm "${PACKAGES[@]}"

log "Enabling NetworkManager.service (system-level, not --user)..."
run sudo systemctl enable --now NetworkManager.service

log "Enabling bluetooth.service (system-level, not --user)..."
run sudo systemctl enable --now bluetooth.service || warn "Could not enable bluetooth.service — probably no Bluetooth hardware on this machine, safe to ignore."

# ── 2a. qmltermwidget — OUR patched fork, not upstream/AUR ───────────────────
# Fixed a genuine bug in TerminalDisplay::setColorScheme upstream: it
# gated every lookup on a once-ever-cached availableColorSchemes()
# list, so a color-scheme file created AFTER the process started (e.g.
# a live theme change) was silently ignored, falling back to the
# default scheme, until a full restart forced a fresh scan. The fix
# calls findColorScheme(name) directly (which already does a correct,
# uncached, fresh per-name lookup) instead of gating on that cached
# list. provides/conflicts=qmltermwidget in our PKGBUILD means pacman
# treats this as a drop-in replacement for the real package — nothing
# else needs to reference "qmltermwidget" by name anywhere else in
# this script; it was deliberately REMOVED from the PACKAGES array
# above, since it's no longer coming from yay/AUR at all.
step "Building patched qmltermwidget (fixes live terminal theming — see comment above)"
# Deliberately split build from install here: `makepkg -si` bundles the
# (noisy, no-privilege) compile step with a (privileged) `sudo pacman -U`
# at the end. Backgrounding the whole thing behind a closed stdin (safe
# for the compile part) meant that final internal sudo call — if it ever
# needed to re-check/re-prompt for credentials — had nowhere to read from
# and failed instantly ("sudo: timed out reading password"). The plain
# `sudo systemctl enable`/`chown`/`chsh` calls elsewhere in this script
# never had this problem, because they run in the foreground with a real
# stdin — so the fix is to do the same here: build quietly in the
# background, then install in the foreground where sudo behaves normally.
QMLTERMWIDGET_PKG_DIR="$REPO_DIR/packaging/qmltermwidget-nisfere"
run_quiet "Compiling qmltermwidget-nisfere" bash -c "cd '$QMLTERMWIDGET_PKG_DIR' && makepkg -sf --noconfirm"
log "Installing qmltermwidget-nisfere (uses sudo — this step is NOT hidden, so a password prompt would show up here normally if one's ever needed)..."
run bash -c "cd '$QMLTERMWIDGET_PKG_DIR' && sudo pacman -U --noconfirm \$(makepkg --packagelist)"

# ── 2b. QMLTermWidget color-schemes dir ownership ────────────────────────────
QMLTERMWIDGET_SCHEMES_DIR="/usr/lib/qt6/qml/QMLTermWidget/color-schemes"
if [[ -d "$QMLTERMWIDGET_SCHEMES_DIR" ]]; then
    log "Handing ownership of $QMLTERMWIDGET_SCHEMES_DIR to $USER (for live terminal theming)..."
    run sudo chown -R "$USER":"$USER" "$QMLTERMWIDGET_SCHEMES_DIR"
else
    warn "$QMLTERMWIDGET_SCHEMES_DIR not found — qmltermwidget may have installed elsewhere on this system. Terminal theming won't work until you locate the real color-schemes dir and chown it yourself (see comment above this step in install.sh)."
fi

log "Setting up XDG user directories..."
run xdg-user-dirs-update

run mkdir -p "$HOME/.config"

step "Installing dotfiles (hypr, qtengine, gtk-3.0, gtk-4.0, xfce4)"
install_dotdir "hypr"
install_dotdir "fontconfig"
install_dotdir "qtengine"
install_dotdir "gtk-3.0"
install_dotdir "gtk-4.0"
install_dotdir "bpytop"
install_dotdir "alacritty"
install_dotdir "fastfetch"

install_zsh() {
    step "Configuring Zsh (dotfiles, plugins, default shell)"
    copy_backed_up "$REPO_DIR/dots/zsh/.zshrc" "$HOME/.zshrc"
    copy_backed_up "$REPO_DIR/dots/zsh/.profile" "$HOME/.profile"

    local zsh_dir="$NISFERE_DIR/zsh"
    local plugins_dir="$zsh_dir/plugins"
    run mkdir -p "$plugins_dir"

    local plugin
    for plugin in zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search; do
        if [[ ! -d "$plugins_dir/$plugin" ]]; then
            run_quiet "Cloning $plugin" git clone "https://github.com/zsh-users/$plugin.git" "$plugins_dir/$plugin"
        fi
    done

    local history_file="$HOME/.zsh_history"
    if [[ ! -f "$history_file" ]]; then
        run touch "$history_file"
        run chmod 600 "$history_file"
    fi

    run sudo chsh -s /bin/zsh "$USER"
    log "Zsh configured (default shell — takes effect on your next login)."
}
install_zsh

fi # end one-time setup (UPDATE_MODE -eq 0)

step "Syncing daemon + shell + templates/themes -> $NISFERE_DIR"
run mkdir -p "$NISFERE_DIR"
copy_backed_up "$REPO_DIR/daemon" "$NISFERE_DIR/daemon"
run rm -f "$NISFERE_DIR/daemon/output.log" "$NISFERE_DIR/daemon/output2.log"
copy_backed_up "$REPO_DIR/shell" "$NISFERE_DIR/shell"
copy_backed_up "$REPO_DIR/templates" "$NISFERE_DIR/templates"
copy_backed_up "$REPO_DIR/themes" "$NISFERE_DIR/themes"
copy_backed_up "$REPO_DIR/templates.json" "$NISFERE_DIR/templates.json"

QUICKSHELL_DEFAULT_DIR="$HOME/.config/quickshell"
if [[ $UPDATE_MODE -eq 0 ]]; then
    if [[ -e "$QUICKSHELL_DEFAULT_DIR" || -L "$QUICKSHELL_DEFAULT_DIR" ]]; then
        warn "Existing $QUICKSHELL_DEFAULT_DIR found — backing up to ${QUICKSHELL_DEFAULT_DIR}.bak-$(date +%s)"
        run mv "$QUICKSHELL_DEFAULT_DIR" "${QUICKSHELL_DEFAULT_DIR}.bak-$(date +%s)"
    fi
    run ln -s "$NISFERE_DIR/shell" "$QUICKSHELL_DEFAULT_DIR"
else
    if [[ ! -L "$QUICKSHELL_DEFAULT_DIR" ]]; then
        warn "$QUICKSHELL_DEFAULT_DIR isn't a symlink to $NISFERE_DIR/shell — something's unusual about this install. Leaving it alone; check it manually if the shell doesn't pick up the update."
    fi
fi

if [[ $UPDATE_MODE -eq 0 ]]; then

step "Setting up cache/data directories and system defaults"
log "Creating cache/data directories..."
run mkdir -p "$HOME/.cache/nisfere"
run mkdir -p "$HOME/Pictures/Wallpapers"
run mkdir -p "$HOME/Pictures/Screenshots"
run mkdir -p "$HOME/Videos/Recordings"

create_cache_file() {
    local name="$1"
    local default_content="$2"
    local dst="$HOME/.cache/nisfere/$name"
    if [[ -f "$dst" ]]; then
        return
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "\033[2m[dry-run]\033[0m write $dst: $default_content"
    else
        echo "$default_content" > "$dst"
    fi
}

log "Applying Papirus icon theme (best-effort gsettings, harmless if it no-ops)..."
run gsettings set org.gnome.desktop.interface icon-theme 'Papirus' || true
run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the sudoers prompt in dry-run mode."
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Allow passwordless 'pacman' for in-UI Arch updates? (adds a sudoers rule) [y/N] " allow_nopasswd
    if [[ "$allow_nopasswd" =~ ^[Yy]$ ]]; then

        echo "${SUDO_USER:-$USER} ALL=(ALL) NOPASSWD: /usr/bin/pacman --version, /usr/bin/pacman -Syu --noconfirm" | sudo tee /etc/sudoers.d/nisfere-pacman >/dev/null

        sudo chmod 0440 /etc/sudoers.d/nisfere-pacman
        log "Passwordless pacman enabled for strictly in-UI updates (-Syu)."
    else
        warn "Skipped — Arch updates in the UI will fall back to a polkit (pkexec) prompt. Make sure a polkit agent is running (e.g. exec-once in Hyprland: /usr/lib/polkit-kde-authentication-agent-1)."
    fi
fi

step "Docker (optional — powers the Dashboard's Docker tab)"
if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the Docker prompt in dry-run mode."
elif command -v docker >/dev/null 2>&1; then
    log "Docker is already installed — skipping the install prompt."
    if systemctl is-enabled --quiet docker.service 2>/dev/null; then
        log "docker.service is already enabled."
    else
        run sudo systemctl enable --now docker.service
    fi
    if groups "$USER" | grep -qw docker; then
        log "$USER is already in the docker group."
    else
        run sudo usermod -aG docker "$USER"
        log "Added $USER to the docker group — log out and back in for it to take effect."
    fi
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Install Docker Engine (for the Dashboard's Docker tab)? [y/N] " install_docker
    if [[ "$install_docker" =~ ^[Yy]$ ]]; then
        run_quiet "Installing docker, docker-compose, python-docker" yay -S --needed --noconfirm docker docker-compose python-docker
        run sudo systemctl enable --now docker.service
        run sudo usermod -aG docker "$USER"
        log "Docker installed and enabled. Log out and back in for group membership to take effect."
    else
        warn "Skipped — the Docker tab won't have anything to show, but nothing else is affected."
    fi
fi

KNOWN_DMS=(sddm gdm lightdm ly greetd)

detect_active_dm() {
    local dm
    for dm in "${KNOWN_DMS[@]}"; do
        if systemctl is-enabled --quiet "${dm}.service" 2>/dev/null; then
            echo "$dm"
            return 0
        fi
    done
    return 1
}

step "Display manager (optional — graphical login screen)"
if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the SDDM prompt in dry-run mode."
else
    active_dm="$(detect_active_dm || true)"
    if [[ -n "$active_dm" ]]; then
        log "A display manager is already enabled (${active_dm}.service) — skipping the SDDM prompt."
    else
        echo
        read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Install SDDM (graphical login screen)? [y/N] " install_sddm
        if [[ "$install_sddm" =~ ^[Yy]$ ]]; then
            run_quiet "Installing SDDM" yay -S --needed --noconfirm sddm
            run sudo systemctl enable sddm.service
            log "SDDM installed and enabled — will show a login screen starting your NEXT boot."
        else
            warn "Skipped — you'll start Hyprland manually (start-hyprland) from a TTY each boot, or via the prompt at the end of this script for right now."
        fi
    fi
fi

fi # end one-time setup (UPDATE_MODE -eq 0), part 2

step "Installing the daemon's systemd --user service + socket"
run mkdir -p "$HOME/.config/systemd/user"
run cp "$REPO_DIR/dots/systemd/nisfere-daemon.service" "$HOME/.config/systemd/user/nisfere-daemon.service"
run cp "$REPO_DIR/dots/systemd/nisfere-daemon.socket" "$HOME/.config/systemd/user/nisfere-daemon.socket"
run systemctl --user daemon-reload

if [[ $UPDATE_MODE -eq 0 ]]; then
    run systemctl --user enable --now nisfere-daemon.socket
    log "Daemon socket enabled and listening (daemon service itself starts on-demand, on first connection)."
else
    if [[ $DRY_RUN -eq 0 ]] && systemctl --user is-active --quiet nisfere-daemon.socket; then
        log "Restarting nisfere-daemon.socket to pick up the updated daemon code..."
        run systemctl --user restart nisfere-daemon.socket
    else
        log "Daemon socket isn't currently active — nothing to restart, it'll come up fresh (with the updated code) next time it's started."
    fi
fi

if [[ $UPDATE_MODE -eq 0 ]]; then

step "Applying the default theme (tokyo-night, dark)"
SOCKET_PATH="/tmp/nisfere-shell.sock"

log "Waiting for the daemon socket to come up..."
if [[ $DRY_RUN -eq 0 ]]; then
    for _ in $(seq 1 20); do
        [[ -S "$SOCKET_PATH" ]] && break
        sleep 0.5
    done
    if [[ ! -S "$SOCKET_PATH" ]]; then
        warn "Daemon socket never appeared at $SOCKET_PATH — skipping default theme apply. Check 'systemctl --user status nisfere-daemon.socket nisfere-daemon.service' and 'journalctl --user -u nisfere-daemon' and apply a theme manually from the shell once it's running."
    fi
fi

log "Applying default theme (tokyo-night, dark) via daemon socket..."
DEFAULT_THEME_MSG='{"module": "theme", "action": "set_colors", "payload": {"theme_name": "tokyo-night", "mode": "dark"}}'

if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "\033[2m[dry-run]\033[0m send to $SOCKET_PATH: $DEFAULT_THEME_MSG"
elif [[ -S "$SOCKET_PATH" ]]; then
    python3 -c "
import socket
msg = '''$DEFAULT_THEME_MSG''' + chr(10)
try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect('$SOCKET_PATH')
    s.sendall(msg.encode())
    s.close()
    print('Default theme request sent.')
except Exception as e:
    print(f'Could not reach daemon socket: {e}')
"
fi

fi # end first-run defaults (UPDATE_MODE -eq 0)

step "Done"
if [[ $DRY_RUN -eq 1 ]]; then
    log "Dry run complete — nothing was changed."
elif [[ $UPDATE_MODE -eq 1 ]]; then
    log "Update complete!"
else
    log "Install complete!"
fi
if [[ $DRY_RUN -eq 0 && -f "$LOG_FILE" ]]; then
    log "Build/install logs from this run: $LOG_FILE"
fi
echo

if [[ $UPDATE_MODE -eq 0 ]]; then
    echo "Next steps:"
    echo "  1. Drop at least one wallpaper image into ~/Pictures/Wallpapers/"
    echo "     (a default static theme is already applied, but no wallpaper is set yet)."
    echo "  2. Check dots/hypr/modules/autostart.lua includes:"
    echo "       exec-once = quickshell > ~/.cache/nisfere/quickshell.log 2>&1"
    echo "     (no -p needed anymore — ~/.config/quickshell now symlinks to the"
    echo "     real shell folder, so the default path is already correct, and"
    echo "     'qs ipc call'/'qs ipc show' will find the running instance too)."
    echo "  3. systemctl --user status nisfere-daemon.socket nisfere-daemon.service"
    echo "     -> the .socket should show 'active (listening)'; the .service starts"
    echo "     automatically on first connection, no need to start it yourself."
    echo "  4. journalctl --user -u nisfere-daemon -f   -> daemon logs, if anything looks off."
fi

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the Hyprland reload / launch step in dry-run mode."
elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    log "Detected an active Hyprland session — reloading config."
    run hyprctl reload

    if [[ $UPDATE_MODE -eq 1 ]] && pgrep -x quickshell >/dev/null 2>&1; then
        log "Restarting Quickshell to pick up the updated shell..."
        run pkill -x quickshell
        sleep 0.3
        run bash -c "mkdir -p '$HOME/.cache/nisfere' && quickshell > '$HOME/.cache/nisfere/quickshell.log' 2>&1 &"
    elif ! pgrep -x quickshell >/dev/null 2>&1; then
        log "Quickshell isn't running — starting it in the background."
        run bash -c "mkdir -p '$HOME/.cache/nisfere' && quickshell > '$HOME/.cache/nisfere/quickshell.log' 2>&1 &"
    else
        log "Quickshell is already running — leaving it as is."
    fi
elif [[ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]]; then
    warn "Detected an SSH session — can't launch a Wayland/Hyprland session from here (no real seat/display to render into). Log in on the actual console/TTY and run 'Hyprland', or reboot into it."
elif [[ $UPDATE_MODE -eq 1 ]]; then
    warn "Not currently inside a Hyprland session — nothing running to restart. The update will take effect next time you start Hyprland."
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Launch Hyprland now? (replaces this shell session) [y/N] " launch_now
    if [[ "$launch_now" =~ ^[Yy]$ ]]; then
        log "Launching Hyprland via start-hyprland..."
        exec start-hyprland
    else
        log "Skipped — log out and start a Hyprland session (or reboot) whenever you're ready."
    fi
fi