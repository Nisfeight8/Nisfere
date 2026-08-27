# greetd does NOT source shell rc files (.zshrc etc) — it execs the
# session command directly, no login shell involved. Without this,
# anything greetd launches (Hyprland itself, and everything Hyprland
# spawns) never sees ~/.local/bin or ~/.npm-global/bin, even though
# .zshrc adds them for interactive shells. ~/.profile is what actually
# gets sourced in that path (per the ArchWiki greetd page).
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"