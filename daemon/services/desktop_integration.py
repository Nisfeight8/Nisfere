"""
DesktopIntegration — everything that reaches out and pokes the running
desktop: setting the wallpaper via awww, recoloring Papirus folders,
forcing GTK to reload. No state, no rendering, no color extraction —
just OS-facing side effects. Threading policy for these lives with the
caller (ThemeManager), not here, so it stays in one place.
"""

import logging
import subprocess
from pathlib import Path

from .color_utils import hue_to_papirus_color

logger = logging.getLogger(__name__)


class DesktopIntegration:
    def apply_wallpaper(self, path: str) -> None:
        subprocess.run(
            ["awww", "img", path, "--transition-type", "center"], check=False
        )

    def preview_wallpaper(self, path: str) -> None:
        subprocess.run(["awww", "img", path, "--transition-type", "none"], check=False)

    def sync_papirus_folders(self, accent_hex: str) -> None:
        """
        Recolors Papirus folder icons to match the current accent color.
        Uses a nearest-neighbor RGB distance algorithm against the known
        Papirus folder color palette.
        """
        try:
            if (
                subprocess.run(
                    ["which", "papirus-folders"], capture_output=True, check=False
                ).returncode
                != 0
            ):
                return

            papirus_paths = [
                Path("/usr/share/icons/Papirus"),
                Path("/usr/share/icons/Papirus-Dark"),
                Path.home() / ".local/share/icons/Papirus",
                Path.home() / ".icons/Papirus",
            ]
            if not any(p.exists() for p in papirus_paths):
                return

            hex_color = accent_hex.lstrip("#")
            if len(hex_color) != 6:
                return

            # Target RGB from the accent hex
            target_r, target_g, target_b = (
                int(hex_color[i : i + 2], 16) for i in (0, 2, 4)
            )

            # The exact color palette supported by papirus-folders
            papirus_palette = {
                "black": (84, 84, 84),
                "blue": (82, 148, 226),
                "bluegrey": (84, 110, 122),
                "breeze": (61, 174, 233),
                "brown": (121, 85, 72),
                "carmine": (224, 79, 95),
                "cyan": (0, 188, 212),
                "darkcyan": (0, 150, 136),
                "deeporange": (255, 112, 67),
                "green": (76, 175, 80),
                "grey": (158, 158, 158),
                "indigo": (63, 81, 181),
                "magenta": (233, 30, 99),
                "nordic": (76, 86, 106),
                "orange": (255, 152, 0),
                "palebrown": (161, 136, 127),
                "paleorange": (255, 183, 77),
                "pink": (244, 143, 177),
                "red": (244, 67, 54),
                "teal": (0, 150, 136),
                "violet": (126, 87, 194),
                "white": (250, 250, 250),
                "yellow": (255, 235, 59),
            }

            # Find the closest matching Papirus color using simple RGB Euclidean distance
            best_color_name = "blue"
            min_distance = float("inf")

            for name, (pr, pg, pb) in papirus_palette.items():
                distance = (
                    ((target_r - pr) ** 2)
                    + ((target_g - pg) ** 2)
                    + ((target_b - pb) ** 2)
                )
                if distance < min_distance:
                    min_distance = distance
                    best_color_name = name

            color = best_color_name

            # Detect which Papirus variant is currently active
            icon_theme_result = subprocess.run(
                ["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"],
                capture_output=True,
                text=True,
                check=False,
            )
            active_icon_theme = icon_theme_result.stdout.strip().strip("'")
            papirus_theme = (
                active_icon_theme if "apirus" in active_icon_theme else "Papirus"
            )

            # Run and wait so icon cache is updated before GTK reload
            subprocess.run(
                ["papirus-folders", "-C", color, "--theme", papirus_theme],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            logger.info(
                "Papirus folders → %s (theme=%s accent=%s)",
                color,
                papirus_theme,
                accent_hex,
            )

        except Exception as e:
            logger.warning("Papirus sync failed: %s", e)

    def reload_gtk(
        self, mode: str, cursor_theme: str = "", cursor_size: int = 24
    ) -> None:
        """
        Forces GTK3/4 apps to pick up the new theme, and updates the
        live cursor (hyprctl setcursor) + GTK's own cursor settings.

        gsettings alone doesn't work under Hyprland (or any non-GNOME
        compositor) — it writes to the dconf database, but nothing
        actually applies that to running/launching GTK apps without
        gnome-settings-daemon (part of a full GNOME session, which
        Hyprland doesn't have). settings.ini is what GTK3/4 actually
        read directly, regardless of desktop environment — the
        reliable mechanism, not just a fallback. gsettings is still
        called too since it's harmless and some portal-aware apps do
        check it.

        cursor_theme/cursor_size are passed in (not hardcoded) because
        this method does a FULL overwrite of settings.ini each call —
        omitting them here would silently wipe the cursor theme out of
        GTK's settings on every future dark/light toggle, even though
        Hyprland/Qt (which read XCURSOR_THEME/XCURSOR_SIZE env vars
        instead, via variables.lua.template) would be unaffected.
        - Uses adw-gtk3 (no dark/light suffix) — our CSS variables handle colors.
        """
        gtk_theme = "adw-gtk3-dark" if mode == "dark" else "adw-gtk3"

        try:
            subprocess.run(
                ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", ""],
                check=False,
            )
        except Exception as e:
            logger.warning("gsettings gtk-theme reset failed (non-fatal): %s", e)

        try:
            subprocess.run(
                [
                    "gsettings",
                    "set",
                    "org.gnome.desktop.interface",
                    "gtk-theme",
                    gtk_theme,
                ],
                check=False,
            )
        except Exception as e:
            logger.warning("gsettings gtk-theme set failed (non-fatal): %s", e)

        if cursor_theme:
            try:
                subprocess.run(
                    [
                        "gsettings",
                        "set",
                        "org.gnome.desktop.interface",
                        "cursor-theme",
                        cursor_theme,
                    ],
                    check=False,
                )
            except Exception as e:
                logger.warning("gsettings cursor-theme set failed (non-fatal): %s", e)

        settings_ini = (
            "[Settings]\n"
            f"gtk-theme-name={gtk_theme}\n"
            "gtk-icon-theme-name=Papirus\n"
            f"gtk-cursor-theme-name={cursor_theme}\n"
            f"gtk-cursor-theme-size={cursor_size}\n"
            f"gtk-application-prefer-dark-theme={'1' if mode == 'dark' else '0'}\n"
        )

        for gtk_dir in ("gtk-3.0", "gtk-4.0"):
            dst = Path.home() / ".config" / gtk_dir / "settings.ini"
            try:
                dst.parent.mkdir(parents=True, exist_ok=True)
                dst.write_text(settings_ini)
            except Exception as e:
                logger.warning("Failed to write %s: %s", dst, e)

        logger.debug(
            "GTK reloaded (mode=%s, theme=%s, cursor=%s@%s)",
            mode,
            gtk_theme,
            cursor_theme,
            cursor_size,
        )

    def reload_hyprland(self, cursor_theme: str = "", cursor_size: int = 24) -> None:
        """
        Updates the live cursor for hyprcursor-aware apps and reloads Hyprland.
        """
        if cursor_theme:
            try:
                subprocess.run(
                    ["hyprctl", "setcursor", cursor_theme, str(cursor_size)],
                    check=False,
                )
                logger.debug("Hyprland live cursor updated.")
            except Exception as e:
                logger.warning("hyprctl setcursor failed (non-fatal): %s", e)

        try:
            subprocess.run(["hyprctl", "reload"], check=False)
            logger.debug("Hyprland configuration reloaded.")
        except Exception as e:
            logger.warning("hyprctl reload failed: %s", e)

    def reload_thunar(self) -> None:
        """
        Checks if Thunar is running. If not, runs `thunar -q` in the background
        to ensure any stuck daemon is killed/refreshed.
        """
        try:
            result = subprocess.run(
                ["pgrep", "-x", "thunar"], capture_output=True, check=False
            )
            is_running = result.returncode == 0

            if is_running:
                logger.debug(
                    "Thunar is running, skipping reload so we don't close user windows."
                )
            else:
                logger.debug("Thunar is not running, issuing 'thunar -q' just in case.")
                subprocess.run(
                    ["thunar", "-q"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
        except Exception as e:
            logger.warning("Thunar check/reload failed: %s", e)

    def reload_desktop(
        self, mode: str, cursor_theme: str = "", cursor_size: int = 24
    ) -> None:
        """
        Central orchestration method for all desktop-related reloads.
        """
        logger.info("Initiating full desktop reload...")
        self.reload_gtk(mode, cursor_theme, cursor_size)
        self.reload_hyprland(cursor_theme, cursor_size)
        self.reload_thunar()
        logger.info("Desktop reload complete.")
