"""
Pure color-math helpers — no filesystem, no state, no subprocess.
Shared by TemplateRenderer (Jinja2 filters) and DesktopIntegration
(Papirus hue matching), so they live here instead of being duplicated
or stuck inside a single "does everything" service.
"""


def filter_strip(hex_val: str) -> str:
    return hex_val.lstrip("#") if isinstance(hex_val, str) else hex_val


def filter_lighten(hex_val: str, amount: float = 0.1) -> str:
    hex_val = hex_val.lstrip("#")
    rgb = [int(hex_val[i : i + 2], 16) for i in (0, 2, 4)]
    new_rgb = [min(255, int(c + (255 - c) * amount)) for c in rgb]
    return f"#{new_rgb[0]:02x}{new_rgb[1]:02x}{new_rgb[2]:02x}"


def filter_darken(hex_val: str, amount: float = 0.1) -> str:
    hex_val = hex_val.lstrip("#")
    rgb = [int(hex_val[i : i + 2], 16) for i in (0, 2, 4)]
    new_rgb = [max(0, int(c * (1 - amount))) for c in rgb]
    return f"#{new_rgb[0]:02x}{new_rgb[1]:02x}{new_rgb[2]:02x}"


def filter_rgb(hex_val: str) -> str:
    """Converts #rrggbb → R,G,B — required by KColorScheme format."""
    hex_val = hex_val.lstrip("#")
    r, g, b = (int(hex_val[i : i + 2], 16) for i in (0, 2, 4))
    return f"{r},{g},{b}"


def filter_lua_bool(value) -> str:
    """Python's str(True)/str(False) → 'True'/'False' (capitalized),
    but Lua needs lowercase true/false — this filter fixes that."""
    return "true" if value else "false"


def hue_to_papirus_color(hue: float, pale: bool) -> str:
    """Maps HSV hue (0–360) to the closest Papirus folder color name."""
    if pale:
        if hue < 15 or hue >= 345:
            return "palered"
        if hue < 40:
            return "paleorange"
        if hue < 70:
            return "yellow"  # no pale yellow exists
        if hue < 150:
            return "palegreen"
        if hue < 195:
            return "paleteal"
        if hue < 220:
            return "palecyan"
        if hue < 265:
            return "breeze"  # closest pale blue
        if hue < 290:
            return "paleviolet"
        if hue < 320:
            return "palepurple"
        return "palepink"
    else:
        if hue < 15 or hue >= 345:
            return "red"
        if hue < 25:
            return "deeporange"
        if hue < 40:
            return "orange"
        if hue < 70:
            return "yellow"
        if hue < 150:
            return "green"
        if hue < 185:
            return "teal"
        if hue < 205:
            return "cyan"
        if hue < 255:
            return "blue"
        if hue < 275:
            return "indigo"
        if hue < 295:
            return "violet"
        if hue < 320:
            return "purple"
        return "pink"
