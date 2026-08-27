import asyncio
import logging
from dataclasses import dataclass

from services.theme_manager import ThemeManager

logger = logging.getLogger(__name__)

# Module-level singleton — created once when the module loads
theme_manager = ThemeManager()

_VALID_MODES = {"dark", "light"}
_VALID_SCOPES = {"shared", "shell", "hyprland"}


# ── Payload dataclasses ──────────────────────────────────────────────────────


@dataclass
class SetWallpaperPayload:
    wallpaper_path: str
    apply_colors: bool = True
    mode: str = "dark"

    def __post_init__(self):
        if not self.wallpaper_path:
            raise ValueError("wallpaper_path is required")
        if self.mode not in _VALID_MODES:
            raise ValueError(
                f"Invalid mode '{self.mode}', must be one of {_VALID_MODES}"
            )


@dataclass
class SetColorsPayload:
    theme_name: str
    mode: str = "dark"

    def __post_init__(self):
        if not self.theme_name:
            raise ValueError("theme_name is required")
        if self.mode not in _VALID_MODES:
            raise ValueError(
                f"Invalid mode '{self.mode}', must be one of {_VALID_MODES}"
            )


@dataclass
class PreviewWallpaperPayload:
    wallpaper_path: str

    def __post_init__(self):
        if not self.wallpaper_path:
            raise ValueError("wallpaper_path is required")


@dataclass
class SetSettingPayload:
    key: str
    value: object
    # NEW — which style bucket to write into. Defaults to "shared" so
    # existing QML callers that don't know about scopes yet still work
    # (radius/fontName-style settings are shared anyway).
    scope: str = "shared"

    def __post_init__(self):
        if not self.key:
            raise ValueError("key is required")
        if self.scope not in _VALID_SCOPES:
            raise ValueError(
                f"Invalid scope '{self.scope}', must be one of {_VALID_SCOPES}"
            )


@dataclass
class SetChromaSettingPayload:
    key: str
    value: object

    def __post_init__(self):
        if not self.key:
            raise ValueError("key is required")


# ── Command handler ───────────────────────────────────────────────────────────


async def handle_command(action: str, payload: dict, sock) -> None:
    try:
        match action:
            case "set_wallpaper":
                p = SetWallpaperPayload(**payload)
                success = await asyncio.to_thread(
                    theme_manager.set_wallpaper,
                    p.wallpaper_path,
                    p.apply_colors,
                    p.mode,
                )
                await sock.send(
                    {
                        "type": "theme_applied",
                        "payload": {"success": success, "wallpaper": p.wallpaper_path},
                    }
                )

            case "set_colors":
                p = SetColorsPayload(**payload)
                success = await asyncio.to_thread(
                    theme_manager.set_colors, p.theme_name, p.mode
                )
                await sock.send(
                    {
                        "type": "theme_applied",
                        "payload": {"success": success, "theme": p.theme_name},
                    }
                )

            case "preview_wallpaper":
                p = PreviewWallpaperPayload(**payload)
                await asyncio.to_thread(
                    theme_manager.preview_wallpaper, p.wallpaper_path
                )
                # No response needed for preview

            case "get_wallpapers":
                wallpapers = await asyncio.to_thread(theme_manager.get_wallpapers)
                await sock.send(
                    {
                        "type": "wallpapers_list",
                        "payload": {"wallpapers": wallpapers},
                    }
                )

            case "get_themes":
                themes = await asyncio.to_thread(theme_manager.get_themes)
                await sock.send(
                    {
                        "type": "themes_list",
                        "payload": {"themes": themes},
                    }
                )

            case "get_state":
                state = await asyncio.to_thread(theme_manager.get_state)
                await sock.send(
                    {
                        "type": "theme_state",
                        "payload": state or {},
                    }
                )
            case "toggle_mode":
                result = await asyncio.to_thread(theme_manager.toggle_mode)
                await sock.send(
                    {
                        "type": "theme_mode_toggled",
                        "payload": result,
                    }
                )

            case "set_setting":
                # Entry point for the general-settings UI (radius,
                # fontName, widgetOpacity, windowGapsIn, ... — any key,
                # tagged with which style scope it belongs to). See
                # ThemeManager.set_setting / StateManager for the
                # underlying shared/shell/hyprland scope design.
                p = SetSettingPayload(**payload)
                result = await asyncio.to_thread(
                    theme_manager.set_setting, p.key, p.value, p.scope
                )
                await sock.send(
                    {
                        "type": "setting_updated",
                        "payload": result,
                    }
                )

            case "set_chroma_setting":
                # Entry point for a future settings UI's "chroma
                # extraction" tab (algorithm/saturation/bg_saturation/
                # contrast/resize_to). Deliberately a SEPARATE action
                # from set_setting — chroma_settings live outside the
                # shared/shell/hyprland style scopes entirely (see
                # StateManager's _DEFAULT_CHROMA_SETTINGS), and unlike
                # a style setting, changing one of these live-reapplies
                # colors from the CURRENT wallpaper if one's active —
                # see ThemeManager.set_chroma_setting for why that's
                # done via _extract_and_apply() rather than
                # set_wallpaper() (avoids re-triggering the awww
                # transition on every slider tweak).
                p = SetChromaSettingPayload(**payload)
                result = await asyncio.to_thread(
                    theme_manager.set_chroma_setting, p.key, p.value
                )
                await sock.send(
                    {
                        "type": "chroma_setting_updated",
                        "payload": result,
                    }
                )

            case _:
                logger.warning("Unknown theme action: '%s'", action)

    except (ValueError, TypeError) as e:
        # Bad payload — client error, warn only
        logger.warning("Invalid payload for '%s': %s", action, e)
        await sock.send(
            {
                "type": "error",
                "payload": {"action": action, "error": str(e)},
            }
        )
    except Exception as e:
        # Unexpected — internal error
        logger.error("Unexpected error in theme action '%s': %s", action, e)
        await sock.send(
            {
                "type": "error",
                "payload": {"action": action, "error": "Internal daemon error"},
            }
        )
