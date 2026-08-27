"""
StateManager — owns ~/.cache/nisfere/state.json exclusively.

style is split into three explicit scopes instead of one flat
namespace, matching who actually reads what:

  shared:   colorN, background, foreground, cursor, radius, fontName —
            anything both Quickshell (bar/widgets) and Hyprland need.
  shell:    Quickshell-only knobs (barHeight, widgetOpacity, ...).
  hyprland: Hyprland-only knobs (gaps, blur, shadow, cursor size, ...).

ThemeManager (and anything else) should go THROUGH this rather than
touching state.json directly — this is the only class that reads or
writes that file.
"""

import json
import logging
import os
from dataclasses import dataclass, field
from pathlib import Path

logger = logging.getLogger(__name__)

_SCOPES = ("shared", "shell", "hyprland")

# nisfere_chroma.py's own tuning knobs — kept as its own top-level
# dict, NOT inside style/shared/shell/hyprland, since these affect
# HOW colors get extracted, not the resulting visual style itself.
# No template ever reads these.
_DEFAULT_CHROMA_SETTINGS = {
    "algorithm": "median_cut",
    "saturation": 1.3,
    "bg_saturation": 0.08,
    "contrast": 1.0,
    "resize_to": 200,
}

# Keys that lived in the OLD flat style dict and are Hyprland- or
# shell-only. Used ONLY once, to bucket a pre-existing flat
# state.json the first time it's loaded after upgrading. Anything
# not listed here defaults to "shared" — the safe choice, since it
# keeps colors and any future/unknown key visible to both consumers
# instead of silently dropping it from one of them.
_HYPRLAND_ONLY_KEYS = {
    "workspaceGaps",
    "windowGapsIn",
    "windowGapsOut",
    "windowBorderSize",
    "opacityActive",
    "opacityInactive",
    "opacityFullscreen",
    "blurEnabled",
    "blurSize",
    "blurPasses",
    "blurPopups",
    "shadowEnabled",
    "shadowRange",
    "shadowRenderPower",
    "cursorTheme",
    "cursorSize",
}
_SHELL_ONLY_KEYS = {
    "enableWidgetBorders",
    "barHeight",
    "screenBorderSize",
    "widgetOpacity",
}

# Keys inside style.shared that are COMPUTED/DERIVED from the current
# wallpaper/theme — ColorSource.flatten() + StateManager.update_shared()
# overwrite ALL of these wholesale on every theme change (wallpaper
# switch, static theme pick, dark/light toggle). NOT durable user
# preferences in the same sense as radius/fontName/workspacesPerMonitor,
# even though they live in the same "shared" bucket (both kinds need to
# be flat/top-level for Jinja templates like variables.lua.template,
# which read colors AND prefs as plain {{ var }} in the same namespace
# — see the conversation this was hashed out in). A settings UI should
# treat these as READ-ONLY display (palette swatches), never as
# editable persistent fields — editing them directly would just get
# silently wiped on the next wallpaper/theme change.
#
# wallpaper/mode are deliberately NOT listed here — they used to be
# duplicated into shared for template convenience, but no template
# actually reads {{ wallpaper }} or {{ mode }} (confirmed via grep), so
# that duplication was removed entirely. They only exist at the
# top-level ThemeState fields now.
_PALETTE_KEYS = {
    "color0",
    "color1",
    "color2",
    "color3",
    "color4",
    "color5",
    "color6",
    "color7",
    "color8",
    "color9",
    "color10",
    "color11",
    "color12",
    "color13",
    "color14",
    "color15",
    "background",
    "foreground",
    "cursor",
    "backgroundAlt",
    "foregroundAlt",
    "accent",
    "borderColor",
}


def is_palette_key(key: str) -> bool:
    """True if `key` is a computed/derived palette value rather than a
    durable user preference — see _PALETTE_KEYS above for the full
    reasoning. Use this (not a hardcoded list elsewhere) anywhere that
    needs to distinguish the two, so there's exactly one place that
    knows the difference."""
    return key in _PALETTE_KEYS


def _migrate_flat_style(flat: dict) -> dict:
    """One-time bucketing of a pre-refactor flat style dict into the
    new shared/shell/hyprland scopes."""
    bucketed: dict = {"shared": {}, "shell": {}, "hyprland": {}}
    for key, value in flat.items():
        if key in _HYPRLAND_ONLY_KEYS:
            bucketed["hyprland"][key] = value
        elif key in _SHELL_ONLY_KEYS:
            bucketed["shell"][key] = value
        else:
            bucketed["shared"][key] = value
    if flat:
        logger.info(
            "Migrated flat state.json style dict into shared/shell/hyprland scopes"
        )
    return bucketed


@dataclass
class ThemeState:
    """
    ...
    chroma_settings: tuning knobs for nisfere_chroma.py's own
                 extract_palette() (algorithm, saturation, etc.) — see
                 _DEFAULT_CHROMA_SETTINGS above.
    style:       {"shared": {...}, "shell": {...}, "hyprland": {...}}
    terminal_color_scheme: which nisfere-<hash>.colorscheme file is
                 currently valid for the embedded terminal widget (see
                 ThemeManager._update_terminal_color_scheme) — pure
                 metadata about the CURRENT state, same tier as
                 wallpaper/mode/source_type, not a style/template
                 variable, so it lives at this top level rather than
                 inside style.shared.
    """

    wallpaper: str
    mode: str
    source_type: str
    source_name: str | None
    chroma_settings: dict = field(
        default_factory=lambda: dict(_DEFAULT_CHROMA_SETTINGS)
    )
    style: dict = field(
        default_factory=lambda: {"shared": {}, "shell": {}, "hyprland": {}}
    )
    terminal_color_scheme: str = ""

    def to_dict(self) -> dict:
        return {
            "wallpaper": self.wallpaper,
            "mode": self.mode,
            "source_type": self.source_type,
            "source_name": self.source_name,
            "chroma_settings": self.chroma_settings,
            "style": self.style,
            "terminal_color_scheme": self.terminal_color_scheme,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "ThemeState":
        style = data.get("style", {})
        if not any(scope in style for scope in _SCOPES):
            style = _migrate_flat_style(style)
        else:
            for scope in _SCOPES:
                style.setdefault(scope, {})

        # Missing chroma_settings (or missing individual keys within
        # it — e.g. upgrading from before a new knob was added) fall
        # back to defaults, same "fill gaps, never overwrite" spirit
        # as seed_defaults() below.
        chroma_settings = dict(_DEFAULT_CHROMA_SETTINGS)
        chroma_settings.update(data.get("chroma_settings", {}))

        return cls(
            wallpaper=data.get("wallpaper", ""),
            mode=data.get("mode", "dark"),
            source_type=data.get("source_type", "dynamic"),
            source_name=data.get("source_name"),
            chroma_settings=chroma_settings,
            style=style,
            terminal_color_scheme=data.get("terminal_color_scheme", ""),
        )


class StateManager:
    """The ONLY class that reads or writes state.json."""

    def __init__(self, state_path: Path):
        self.state_path = state_path

    # ── Core I/O ─────────────────────────────────────────────────────────

    def load(self) -> ThemeState | None:
        try:
            data = json.loads(self.state_path.read_text())
            return ThemeState.from_dict(data)
        except FileNotFoundError:
            logger.debug("No state file yet at %s", self.state_path)
            return None
        except json.JSONDecodeError as e:
            logger.error("State file is corrupt: %s", e)
            return None

    def save(self, state: ThemeState) -> None:
        """
        Writes via a temp file + os.replace() rather than a direct
        write_text() — that was NOT atomic (open-with-truncate, then
        write, as two separate steps), which left a window where
        Quickshell's FileView (watchChanges: true) could catch the
        file mid-truncate or mid-write and choke on invalid/empty
        JSON. os.replace() is atomic on the same filesystem: any
        reader sees either the complete old file or the complete new
        one, never a torn intermediate state. This was hit in
        practice specifically on toggle_mode, since _apply_colors()
        writes state.json TWICE per call (update_shared() + the
        cursorTheme set_setting() right after) — twice the chances to
        land in the old race window.
        """
        self.state_path.parent.mkdir(parents=True, exist_ok=True)
        data = json.dumps(state.to_dict(), indent=2)
        tmp_path = self.state_path.with_suffix(self.state_path.suffix + ".tmp")
        tmp_path.write_text(data)
        os.replace(tmp_path, self.state_path)
        logger.debug("State saved -> %s", self.state_path)

    def _load_or_new(self) -> ThemeState:
        return self.load() or ThemeState(
            wallpaper="", mode="dark", source_type="dynamic", source_name=None
        )

    # ── Single-setting access (for a future settings UI) ───────────────────

    def get_setting(self, key: str, scope: str | None = None, default=None):
        """
        Reads ANY key from the style namespace — not restricted to a
        fixed whitelist, so a future settings UI can read/write
        arbitrary keys without this class needing changes per key.

        If `scope` is given, looks only there. Otherwise checks
        shared -> shell -> hyprland in that order and returns the
        first match.
        """
        state = self.load()
        if not state:
            return default
        scopes = (scope,) if scope else _SCOPES
        for s in scopes:
            bucket = state.style.get(s, {})
            if key in bucket:
                return bucket[key]
        return default

    def get_editable_shared_settings(self) -> dict:
        """
        The subset of style.shared that's safe for a settings UI to
        list as editable durable preferences — excludes computed
        palette values (see _PALETTE_KEYS/is_palette_key above), which
        get silently overwritten wholesale on the next wallpaper/theme
        change and would confuse a UI that treated them like ordinary
        persistent settings.

        e.g. today this returns {"radius": 20, "fontName": "...",
        "workspacesPerMonitor": 10} — NOT color0..15/background/
        foreground/accent/etc, even though those also live in the same
        shared bucket on disk.
        """
        state = self.load()
        if not state:
            return {}
        shared = state.style.get("shared", {})
        return {k: v for k, v in shared.items() if not is_palette_key(k)}

    def get_palette(self) -> dict:
        """
        The complementary view to get_editable_shared_settings() —
        just the computed palette values, for read-only display (color
        swatches) in a settings UI. Includes 'alpha' too: currently a
        hardcoded constant from ColorSource.flatten() (always 100, not
        actually derived from anything), not read by any template
        right now, but grouped here rather than in the editable-prefs
        view since it isn't a real user preference either — revisit if
        it ever becomes one.
        """
        state = self.load()
        if not state:
            return {}
        shared = state.style.get("shared", {})
        return {k: v for k, v in shared.items() if is_palette_key(k) or k == "alpha"}

    def set_setting(self, key: str, value, scope: str = "shared") -> ThemeState:
        """Updates ONE key in the given scope, preserving everything else."""
        if scope not in _SCOPES:
            raise ValueError(f"Invalid scope '{scope}', must be one of {_SCOPES}")
        state = self._load_or_new()
        state.style.setdefault(scope, {})[key] = value
        self.save(state)
        return state

    def get_chroma_settings(self) -> dict:
        state = self.load()
        return dict(state.chroma_settings) if state else dict(_DEFAULT_CHROMA_SETTINGS)

    def set_chroma_setting(self, key: str, value) -> ThemeState:
        """Updates ONE chroma extraction setting, preserving everything else."""
        state = self._load_or_new()
        state.chroma_settings[key] = value
        self.save(state)
        return state

    def set_terminal_color_scheme(self, name: str) -> ThemeState:
        """
        Updates just the terminal_color_scheme metadata field —
        called after ThemeManager copies the just-rendered
        nisfere.colorscheme to a hash-named file (see
        ThemeManager._update_terminal_color_scheme). Same
        get-or-new/mutate-one-field/save shape as set_setting/
        set_chroma_setting above, preserving everything else.
        """
        state = self._load_or_new()
        state.terminal_color_scheme = name
        self.save(state)
        return state

    # ── Bulk color/theme updates (wallpaper change, theme switch) ───────────

    def update_shared(
        self,
        new_values: dict,
        wallpaper: str,
        mode: str,
        source_type: str,
        source_name: str | None,
    ) -> ThemeState:
        """
        Merges new_values OVER the existing 'shared' scope ONLY —
        shell and hyprland settings (set via set_setting) are left
        completely untouched. This is the fix for the bug where
        changing wallpaper/theme used to reset general settings back
        to hardcoded defaults: a color/theme change now only ever
        touches the shared bucket, by construction.
        """
        existing = self.load()
        style = {
            "shared": dict(existing.style.get("shared", {})) if existing else {},
            "shell": dict(existing.style.get("shell", {})) if existing else {},
            "hyprland": dict(existing.style.get("hyprland", {})) if existing else {},
        }
        style["shared"].update(new_values)

        state = ThemeState(
            wallpaper=wallpaper,
            mode=mode,
            source_type=source_type,
            source_name=source_name,
            style=style,
            chroma_settings=(
                dict(existing.chroma_settings)
                if existing
                else dict(_DEFAULT_CHROMA_SETTINGS)
            ),
            terminal_color_scheme=(existing.terminal_color_scheme if existing else ""),
        )
        self.save(state)
        return state

    # ── Seed defaults ────────────────────────────────────────────────────

    def seed_defaults(self, defaults: dict) -> None:
        """
        defaults: {"shared": {...}, "shell": {...}, "hyprland": {...}}

        Ensures every key in each scope actually EXISTS in state.json,
        writing it in if missing (never overwrites a key already
        there). Call once at daemon startup.
        """
        state = self._load_or_new()
        added: dict[str, list[str]] = {}

        for scope in _SCOPES:
            bucket = state.style.setdefault(scope, {})
            for key, value in defaults.get(scope, {}).items():
                if key not in bucket:
                    bucket[key] = value
                    added.setdefault(scope, []).append(key)

        if added:
            self.save(state)
            logger.info("Seeded missing default settings into state.json: %s", added)
