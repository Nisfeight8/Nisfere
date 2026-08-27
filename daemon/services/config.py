from dataclasses import dataclass, field
from pathlib import Path


@dataclass(frozen=True)
class NisfereConfig:
    """All filesystem paths the daemon touches, in one place."""

    nisfere_dir: Path = field(
        default_factory=lambda: Path("~/.config/nisfere").expanduser()
    )
    wallpapers_dir: Path = field(
        default_factory=lambda: Path("~/Pictures/Wallpapers").expanduser()
    )
    cache_dir: Path = field(
        default_factory=lambda: Path("~/.cache/nisfere").expanduser()
    )

    @property
    def templates_dir(self) -> Path:
        return self.nisfere_dir / "templates"

    @property
    def themes_dir(self) -> Path:
        return self.nisfere_dir / "themes"

    @property
    def template_map_path(self) -> Path:
        return self.nisfere_dir / "templates.json"

    @property
    def state_path(self) -> Path:
        return self.cache_dir / "state.json"