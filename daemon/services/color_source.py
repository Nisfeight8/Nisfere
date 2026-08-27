"""
ColorSource — knows how to GET raw color data and flatten it into
template-ready vars. Doesn't know about templates.json, doesn't touch
state.json, doesn't talk to the desktop. Just: image/theme in, flat
color dict out.
"""

import json
import logging

from .config import NisfereConfig
from .nisfere_chroma import extract_palette

logger = logging.getLogger(__name__)


class ColorSource:
    def __init__(self, config: NisfereConfig):
        self.config = config

    # ── Sources ──────────────────────────────────────────────────────────────

    def extract_dynamic(
        self,
        image_path: str,
        mode: str,
        algorithm: str = "median_cut",
        saturation: float = 1.3,
        bg_saturation: float = 0.08,
        contrast: float = 1.0,
        resize_to: int = 200,
    ) -> dict:
        """
        Extracts colors from the image via our own in-house extractor
        (services/nisfere_chroma.py) — in-process, no subprocess, no
        external `wallust` binary/cache file involved anymore. Tuning
        knobs default to nisfere_chroma's own defaults; ThemeManager
        passes the actual configured values (from StateManager's
        chroma_settings) when calling this.
        """
        import os

        return extract_palette(
            os.path.expanduser(image_path),
            mode=mode,
            algorithm=algorithm,
            saturation=saturation,
            bg_saturation=bg_saturation,
            contrast=contrast,
            resize_to=resize_to,
        )

    def load_static(self, theme_name: str, mode: str = "dark") -> dict:
        """
        Loads a color JSON from ~/.config/nisfere/themes/.
        Resolution order:
          1. {theme_name}-{mode}.json  (e.g. tokyo-night-dark.json)
          2. {theme_name}.json         (mode-agnostic fallback)
        """
        candidates = [
            self.config.themes_dir / f"{theme_name}-{mode}.json",
            self.config.themes_dir / f"{theme_name}.json",
        ]
        for path in candidates:
            if path.exists():
                logger.debug("Loading theme: %s", path.name)
                return json.loads(path.read_text())
        raise FileNotFoundError(
            f"Theme not found: '{theme_name}' (tried {[c.name for c in candidates]})"
        )

    # ── Shaping ──────────────────────────────────────────────────────────────

    def flatten(self, raw_data: dict, mode: str) -> dict:
        """
        Flattens color data into a flat dict of template vars.
        Everything this returns belongs in the 'shared' style scope —
        colors are the one thing both Quickshell and Hyprland always
        need.

        nisfere_chroma.extract_palette() already returns a flat
        {name: "#rrggbb"} dict directly (no nested "special"/"colors"
        keys the way the old external wallust CLI's JSON did) — this
        still handles that OLD nested shape too, for static theme
        JSONs under themes/ that were authored in that format.
        """
        vars_dict: dict = {}

        for k, v in raw_data.items():
            if not isinstance(v, dict):
                vars_dict[k] = v

        for k, v in raw_data.get("special", {}).items():
            vars_dict[k] = v

        for k, v in raw_data.get("colors", {}).items():
            vars_dict[k] = v

        return vars_dict
