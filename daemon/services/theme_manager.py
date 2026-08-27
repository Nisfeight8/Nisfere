"""
ThemeManager — orchestrates a theme change end to end:
  1. get raw colors from ColorSource (nisfere_chroma or static json)
  2. merge them into StateManager's 'shared' scope
  3. re-render everything via TemplateRenderer
  4. trigger desktop side-effects via DesktopIntegration

It doesn't do any of steps 1-4 itself anymore. See:
  color_source.py, template_renderer.py, desktop_integration.py,
  state_manager.py
"""

import hashlib
import logging
import threading
from pathlib import Path

from .config import NisfereConfig
from .color_source import ColorSource
from .color_utils import filter_darken, filter_lighten
from .desktop_integration import DesktopIntegration
from .state_manager import StateManager
from .template_renderer import TemplateRenderer

logger = logging.getLogger(__name__)

_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}

# Seeded into state.json on first daemon startup (see
# StateManager.seed_defaults) so these exist as real, editable values
# from day one — not just QML-side fallback constants nobody's ever
# confirmed are actually in effect.
_DEFAULT_SETTINGS: dict = {
    "shared": {"radius": 20, "fontName": "Noto Nerd Font", "workspacesPerMonitor": 10},
    "shell": {
        "enableWidgetBorders": True,
        "barHeight": 50,
        "screenBorderSize": 10,
        "widgetOpacity": 1.0,
    },
    "hyprland": {
        "workspaceGaps": 20,
        "windowGapsIn": 6,
        "windowGapsOut": 20,
        "windowBorderSize": 2,
        "opacityActive": 0.95,
        "opacityInactive": 0.85,
        "opacityFullscreen": 1.0,
        "blurEnabled": True,
        "blurSize": 8,
        "blurPasses": 3,
        "blurPopups": True,
        "shadowEnabled": True,
        "shadowRange": 15,
        "shadowRenderPower": 4,
        "cursorTheme": "Bibata-Modern-Ice",
        "cursorSize": 24,
    },
}

# Where the qmltermwidget package installs its bundled color-schemes —
# same directory install.sh chown's to the current user (see chat: no
# per-user override location exists upstream, so this is the only
# writable-without-root place ColorSchemeManager actually scans).
# NOT VERIFIED across all setups — standard Arch Qt6 QML plugin path.
# If your qmltermwidget installs elsewhere, this needs to match
# install.sh's own QMLTERMWIDGET_SCHEMES_DIR.
_QMLTERMWIDGET_SCHEMES_DIR = Path("/usr/lib/qt6/qml/QMLTermWidget/color-schemes")
_QMLTERMWIDGET_BASE_SCHEME = _QMLTERMWIDGET_SCHEMES_DIR / "nisfere.colorscheme"


class ThemeManager:
    def __init__(self, config: NisfereConfig | None = None):
        self.config = config or NisfereConfig()
        self._ensure_dirs()

        self.colors = ColorSource(self.config)
        self.renderer = TemplateRenderer(
            self.config.templates_dir, self.config.template_map_path
        )
        self.desktop = DesktopIntegration()
        self.state = StateManager(self.config.state_path)
        self.state.seed_defaults(_DEFAULT_SETTINGS)

    def _ensure_dirs(self) -> None:
        for d in (
            self.config.nisfere_dir,
            self.config.templates_dir,
            self.config.themes_dir,
            self.config.cache_dir,
        ):
            d.mkdir(parents=True, exist_ok=True)

    # ── Public API ───────────────────────────────────────────────────────────

    def set_setting(self, key: str, value, scope: str = "shared") -> dict:
        """
        Updates ONE key in the given style scope (shared/shell/hyprland)
        and re-renders all templates so consumers see the change
        immediately.
        """
        try:
            state = self.state.set_setting(key, value, scope)
            self.renderer.render_all(state.style)
        except Exception as e:
            logger.error("Failed to re-render templates for setting '%s': %s", key, e)
            return {"success": False, "error": str(e)}

        logger.info("Setting updated: %s.%s = %r", scope, key, value)
        return {"success": True, "key": key, "value": value, "scope": scope}

    def set_chroma_setting(self, key: str, value) -> dict:
        """
        Updates ONE nisfere_chroma extraction knob (algorithm/
        saturation/bg_saturation/contrast/resize_to) and, if a
        wallpaper-derived (dynamic) theme is currently active,
        immediately re-extracts + re-applies colors from that SAME
        wallpaper — same instant-feedback idea as set_setting() for
        style values, instead of the change silently sitting inert
        until the next wallpaper switch.

        Deliberately uses _extract_and_apply() directly rather than
        set_wallpaper() — set_wallpaper() also re-triggers
        DesktopIntegration.apply_wallpaper() (the `awww img ...`
        transition), which would restart the wallpaper-set animation
        on every single slider tweak in a settings UI even though the
        image itself never changed, only how it's being color-sampled.
        """
        try:
            state = self.state.set_chroma_setting(key, value)
        except Exception as e:
            logger.error("Failed to update chroma setting '%s': %s", key, e)
            return {"success": False, "error": str(e)}

        reapplied = False
        if state.source_type == "dynamic" and state.wallpaper:
            reapplied = self._extract_and_apply(state.wallpaper, state.mode)

        logger.info(
            "Chroma setting updated: %s = %r (live-reapplied=%s)",
            key,
            value,
            reapplied,
        )
        return {
            "success": True,
            "key": key,
            "value": value,
            "reapplied": reapplied,
        }

    def toggle_mode(self) -> dict:
        state = self.state.load()
        if not state:
            return {"success": False, "error": "No state found"}

        new_mode = "light" if state.mode == "dark" else "dark"
        logger.info("Toggling mode from %s to %s", state.mode, new_mode)

        if state.source_type == "static" and state.source_name:
            success = self.set_colors(state.source_name, new_mode)
        elif state.wallpaper:
            success = self.set_wallpaper(state.wallpaper, True, new_mode)
        else:
            success = False

        return {"success": success, "mode": new_mode}

    def preview_wallpaper(self, wallpaper_path: str) -> None:
        self.desktop.preview_wallpaper(wallpaper_path)

    def set_wallpaper(
        self, wallpaper_path: str, apply_colors: bool, mode: str = "dark"
    ) -> bool:
        self.desktop.apply_wallpaper(wallpaper_path)

        if not apply_colors:
            # Just update wallpaper field in existing state.
            state = self.state.load()
            if state:
                state.wallpaper = wallpaper_path
                self.state.save(state)
            return True

        return self._extract_and_apply(wallpaper_path, mode)

    def _extract_and_apply(self, wallpaper_path: str, mode: str) -> bool:
        """
        The actual extract-colors-from-image-and-apply-them step,
        factored out of set_wallpaper() so set_chroma_setting() can
        re-run just this part (re-extraction with new tuning knobs)
        without also re-triggering the desktop wallpaper-set transition
        via DesktopIntegration.apply_wallpaper() — the image path is
        the same, only how it gets sampled changed.
        """
        chroma_settings = self.state.get_chroma_settings()
        raw = self.colors.extract_dynamic(wallpaper_path, mode, **chroma_settings)
        return self._apply_colors(raw, mode, wallpaper_path, "dynamic", None)

    def set_colors(self, theme_name: str, mode: str = "dark") -> bool:
        raw = self.colors.load_static(theme_name, mode)
        state = self.state.load()
        wallpaper = state.wallpaper if state else ""
        return self._apply_colors(raw, mode, wallpaper, "static", theme_name)

    def get_wallpapers(self) -> list[dict]:
        d = self.config.wallpapers_dir
        if not d.exists():
            logger.warning("Wallpapers directory not found: %s", d)
            return []
        return [
            {"name": p.stem, "path": str(p)}
            for p in sorted(d.iterdir())
            if p.is_file() and p.suffix.lower() in _IMAGE_EXTENSIONS
        ]

    def get_themes(self) -> list[dict]:
        """
        Returns unique theme base names (stripping -dark/-light
        suffixes) together with a color preview for each — read via
        the SAME ColorSource.load_static()/flatten() the daemon
        already uses when actually applying a theme, so the preview
        can never drift out of sync with reality.
        e.g. tokyo-night-dark.json + tokyo-night-light.json →
          [{"name": "tokyo-night", "colors": {...flattened dark palette...}}]
        Preview always reads the dark variant (falling back to light
        if no dark variant exists) regardless of the shell's current
        mode — just a representative swatch for a picker UI. The mode
        toggle still determines which variant actually gets applied.
        """
        d = self.config.themes_dir
        if not d.exists():
            logger.warning("Themes directory not found: %s", d)
            return []

        seen: set[str] = set()
        result: list[dict] = []
        for p in sorted(d.iterdir()):
            if not p.is_file() or p.suffix != ".json":
                continue
            name = p.stem
            for suffix in ("-dark", "-light"):
                if name.endswith(suffix):
                    name = name[: -len(suffix)]
                    break
            if name in seen:
                continue
            seen.add(name)

            preview: dict = {}
            for preview_mode in ("dark", "light"):
                try:
                    raw = self.colors.load_static(name, preview_mode)
                    preview = self.colors.flatten(raw, preview_mode)
                    break
                except FileNotFoundError:
                    continue
                except Exception as e:
                    logger.warning(
                        "Failed to read preview colors for theme '%s': %s", name, e
                    )
                    break

            result.append({"name": name, "colors": preview})
        return result

    def get_state(self) -> dict | None:
        state = self.state.load()
        return state.to_dict() if state else None

    # ── Internal ─────────────────────────────────────────────────────────────

    def _update_terminal_color_scheme(self) -> None:
        """
        qmltermwidget's ColorSchemeManager caches a scheme's parsed
        contents in memory the FIRST time a given name is requested,
        and doesn't re-read the file from disk after that — so simply
        re-rendering the SAME nisfere.colorscheme on every theme
        change is invisible to an already-running terminal widget (see
        chat). Sidesteps this by copying the just-rendered file to a
        NEW name derived from a hash of its own content — a genuinely
        new name has never been requested before, so it's always a
        cache MISS, forcing a fresh disk read every time colors
        actually change. Re-applying the SAME theme produces the SAME
        hash (file already exists, no-op), so this doesn't grow
        unbounded on repeat applies of the same theme — only on
        genuinely distinct color sets (e.g. many different wallpapers
        over time for dynamic theming).

        The shell picks up which name is currently valid via
        state.json's terminal_color_scheme field (see
        StateManager.set_terminal_color_scheme), which ThemeState.qml
        already watches reactively like everything else in that file.

        Best-effort: any failure here (missing dir, permissions, no
        qmltermwidget installed) is logged and swallowed rather than
        failing the whole theme-apply — the rest of the desktop theme
        already applied successfully by this point regardless.
        """
        try:
            if not _QMLTERMWIDGET_BASE_SCHEME.exists():
                logger.debug(
                    "qmltermwidget base colorscheme not found at %s — skipping "
                    "(qmltermwidget not installed, or templates.json doesn't "
                    "include the qmltermwidget.colorscheme template yet)",
                    _QMLTERMWIDGET_BASE_SCHEME,
                )
                return

            content = _QMLTERMWIDGET_BASE_SCHEME.read_bytes()
            digest = hashlib.md5(content).hexdigest()[:8]
            name = f"nisfere-{digest}"
            dst = _QMLTERMWIDGET_SCHEMES_DIR / f"{name}.colorscheme"

            if not dst.exists():
                dst.write_bytes(content)
                logger.debug("Wrote new terminal color scheme: %s", dst)

            self.state.set_terminal_color_scheme(name)
        except Exception as e:
            logger.error("Failed to update terminal color scheme: %s", e)

    def _apply_colors(
        self,
        raw: dict,
        mode: str,
        wallpaper_path: str,
        source_type: str,
        source_name: str | None,
    ) -> bool:
        try:
            shared_vars = self.colors.flatten(raw, mode)

            bg = shared_vars["background"]
            if mode == "light":
                shared_vars["borderColor"] = filter_darken(bg, 0.10)
            else:
                shared_vars["borderColor"] = filter_lighten(bg, 0.10)

            # Merges over existing 'shared' scope only — shell/hyprland
            # settings the user customized via set_setting() survive
            # untouched. This is the actual fix for the "wallpaper
            # change resets my settings" bug.
            state = self.state.update_shared(
                shared_vars, wallpaper_path, mode, source_type, source_name
            )

            # Contrast-matched: Classic (black) on light backgrounds,
            # Ice (white) on dark backgrounds — reversed from this
            # would give the WORST possible contrast in both modes.
            cursor_theme = (
                "Bibata-Modern-Classic" if mode == "light" else "Bibata-Modern-Ice"
            )
            cursor_size = state.style.get("hyprland", {}).get("cursorSize", 24)

            # set_setting() returns a fresh ThemeState — MUST reassign
            # `state` here, or render_all() below renders whatever
            # cursorTheme was already on disk before this call (one
            # theme-apply behind), not the value we just computed.
            state = self.state.set_setting("cursorTheme", cursor_theme, "hyprland")
            self.renderer.render_all(state.style)

            # Must run AFTER render_all() — reads the just-rendered
            # nisfere.colorscheme file to compute this theme's hash.
            self._update_terminal_color_scheme()

            # All desktop side-effect threading lives here, in one
            # place, instead of scattered across services.
            threading.Thread(
                target=self.desktop.sync_papirus_folders,
                args=(state.style.get("shared", {}).get("accent", ""),),
                daemon=True,
            ).start()
            threading.Thread(
                target=self.desktop.reload_desktop,
                args=(mode,),
                kwargs={"cursor_theme": cursor_theme, "cursor_size": cursor_size},
                daemon=True,
            ).start()

            logger.info(
                "Theme applied - mode=%s source=%s", mode, source_name or "dynamic"
            )
            return True

        except Exception as e:
            logger.error("Failed to apply theme: %s", e)
            return False
