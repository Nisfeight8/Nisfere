"""
TemplateRenderer — owns the Jinja2 environment, templates.json, and
writing rendered output to disk. Doesn't know where colors come from
(ColorSource) or how they got merged into state (StateManager) — you
hand it a {"shared": ..., "shell": ..., "hyprland": ...} style dict
and it renders every template with the right scope merged in.
"""

import json
import logging
from pathlib import Path

from jinja2 import Environment, StrictUndefined

from .color_utils import (
    filter_darken,
    filter_lighten,
    filter_lua_bool,
    filter_rgb,
    filter_strip,
)

logger = logging.getLogger(__name__)

_VALID_SCOPES = ("shared", "shell", "hyprland")

# Written to templates.json on first run if the file doesn't exist.
# Each entry: {"targets": [str, ...], "scope": "shared"|"shell"|"hyprland"}
# "scope" says which extra style bucket (on TOP of "shared") gets
# merged in for that template — e.g. a Hyprland template gets
# shared + hyprland vars, and will never see shell-only keys like
# barHeight, so a stray Hyprland-only var can't leak into GTK css.
_DEFAULT_TEMPLATE_MAP: dict = {
    "variables.lua.template": {
        "targets": ["~/.config/hypr/modules/variables.lua"],
        "scope": "hyprland",
    },
    "alacritty-colors.toml": {
        "targets": ["~/.config/alacritty/colors.toml"],
        "scope": "shared",
    },
    "thunar.css": {
        "targets": ["~/.config/gtk-3.0/thunar.css", "~/.config/gtk-4.0/thunar.css"],
        "scope": "shell",
    },
    "adw-gtk3.css": {
        "targets": ["~/.config/gtk-3.0/gtk.css", "~/.config/gtk-4.0/gtk.css"],
        "scope": "shell",
    },
    "bpytop.theme": {
        "targets": ["~/.config/bpytop/themes/nisfere.theme"],
        "scope": "shared",
    },
    "vscode.json": {
        "targets": ["~/.cache/wallust/colors.json"],
        "scope": "shared",
    },
    "vscode": {
        "targets": ["~/.cache/wallust/colors"],
        "scope": "shared",
    },
    "nisfere.colors": {
        "targets": ["~/.config/qtengine/nisfere.colors"],
        "scope": "shared",
    },
    "qmltermwidget.colorscheme": {
        "targets": ["/usr/lib/qt6/qml/QMLTermWidget/color-schemes/nisfere.colorscheme"],
        "scope": "shared",
    },
}


class TemplateRenderer:
    def __init__(self, templates_dir: Path, template_map_path: Path):
        self.templates_dir = templates_dir
        self.template_map_path = template_map_path

        self.env = Environment(undefined=StrictUndefined)
        self.env.filters["strip"] = filter_strip
        self.env.filters["lighten"] = filter_lighten
        self.env.filters["darken"] = filter_darken
        self.env.filters["rgb"] = filter_rgb
        self.env.filters["lua_bool"] = filter_lua_bool

        self.template_map = self._load_template_map()

    # ── templates.json ───────────────────────────────────────────────────────

    def _load_template_map(self) -> dict:
        p = self.template_map_path
        if not p.exists():
            logger.info("templates.json not found — creating with defaults at %s", p)
            p.write_text(json.dumps(_DEFAULT_TEMPLATE_MAP, indent=2))
            return dict(_DEFAULT_TEMPLATE_MAP)

        try:
            raw = json.loads(p.read_text())
        except json.JSONDecodeError as e:
            logger.error("templates.json is invalid (%s) — falling back to defaults", e)
            return dict(_DEFAULT_TEMPLATE_MAP)

        normalized = {
            name: self._normalize_entry(name, entry) for name, entry in raw.items()
        }

        if normalized != raw:
            # Pre-refactor (or otherwise scope-less) entries got
            # upgraded in memory — persist that back to disk so the
            # file reflects reality and the correct scope is visible
            # (and editable) rather than being silently re-guessed on
            # every daemon restart.
            p.write_text(json.dumps(normalized, indent=2))
            logger.info("templates.json migrated to explicit scope format at %s", p)

        return normalized

    @staticmethod
    def _normalize_entry(name: str, entry) -> dict:
        """
        Backwards-compat: pre-refactor templates.json entries were a
        bare str or list[str] with no scope concept. For any of our
        own built-in template names (variables.lua.template ...)
        we know the correct scope from
        _DEFAULT_TEMPLATE_MAP and use THAT — not a blind 'shared' —
        so a Hyprland-only template doesn't end up missing hyprland
        vars (windowGapsIn, blurEnabled, ...) just because the user's
        templates.json predates the scope concept. Only truly unknown
        (e.g. user-added) template names fall back to 'shared'.
        """
        implied_scope = _DEFAULT_TEMPLATE_MAP.get(name, {}).get("scope", "shared")

        if isinstance(entry, dict):
            targets = entry.get("targets", [])
            scope = entry.get("scope", implied_scope)
            if scope not in _VALID_SCOPES:
                logger.warning(
                    "Unknown scope '%s' in templates.json — using 'shared'", scope
                )
                scope = "shared"
            return {
                "targets": [targets] if isinstance(targets, str) else targets,
                "scope": scope,
            }
        targets = [entry] if isinstance(entry, str) else entry
        return {"targets": targets, "scope": implied_scope}

    # ── Rendering ────────────────────────────────────────────────────────────

    def render_all(self, style: dict) -> None:
        """
        style: {"shared": {...}, "shell": {...}, "hyprland": {...}}

        Renders every entry in templates.json with shared + its own
        scope merged (scope-specific values win on key conflict), and
        writes to its target path(s). Values in templates.json can be
        a single path (str) or multiple (list[str]).
        """
        shared = style.get("shared", {})
        failed: list[str] = []

        for template_name, entry in self.template_map.items():
            src = self.templates_dir / template_name

            if not src.exists():
                logger.warning("Template missing, skipping: %s", template_name)
                continue

            template_vars = {**shared, **style.get(entry["scope"], {})}

            try:
                template = self.env.from_string(src.read_text())
                rendered = template.render(**template_vars)
            except Exception as e:
                logger.error("Failed to render %s: %s", template_name, e)
                failed.append(template_name)
                continue

            for target_path in entry["targets"]:
                dst = Path(target_path).expanduser()
                dst.parent.mkdir(parents=True, exist_ok=True)
                try:
                    # Direct write — preserves inode so GTK3 inotify watch works.
                    # GTK watches ~/.config/gtk-3.0/gtk.css by inode; atomic rename
                    # would change the inode and break the live reload watch.
                    dst.write_text(rendered)
                    logger.debug("Rendered %s → %s", template_name, dst)
                except Exception as e:
                    logger.error("Failed to write %s → %s: %s", template_name, dst, e)
                    failed.append(f"{template_name}→{dst.name}")

        if failed:
            raise RuntimeError(f"Render failed for: {failed}")
