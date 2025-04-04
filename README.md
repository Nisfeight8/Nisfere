# Nisfere Arch Installer

![Nisfere Logo](https://img.shields.io/badge/Nisfere-Arch%20Dotfiles-blueviolet)

Nisfere is a setup script and dotfiles collection tailored for Arch Linux users. It includes tools, themes, fonts, and Hyprland configuration to get a beautiful and functional desktop environment quickly.

---

## ✨ Preview


<p align="center">
  <img src="screenshots/dracula.png" alt="Dracula" width="30%" style="margin: 5px;"/>
  <img src="screenshots/tokyo-night.png" alt="Tokyo Night" width="30%" style="margin: 5px;"/>
  <img src="screenshots/nord.png" alt="Nord" width="30%" style="margin: 5px;"/>
</p>

<p align="center">
  <img src="screenshots/catppuccin-mocha.png" alt="Catppuccin Mocha" width="45%" style="margin: 5px;"/>
  <img src="screenshots/solarized.png" alt="Solarized" width="45%" style="margin: 5px;"/>
</p>

---

## 🔧 Requirements
- Arch Linux
- Internet connection
- A non-root user

## 🚀 Features
- Automatic installation of required packages
- ZSH setup with plugins
- Fonts, GTK themes, icons, and cursors
- Hyprland default keybindings
- Panel and theming powered by [Fabric](https://github.com/Fabric-Development/fabric)

---

## 🔧 Installation

```
bash <(wget -qO- https://gist.githubusercontent.com/Nisfeight8/62ee7aed6796641cf5a89a6e482a2519/raw/a7f2b9b251e463cbd901914b550633f79adcdabd/install.sh)
```

---


## ⚙️ Configuration

After installation, Nisfere stores its configuration in the following directory:
```
~/.config/nisfere
```


### 🎨 Custom Themes

To create your own themes, navigate to:

```
~/.config/nisfere/themes/
```

Inside this folder, you can add a subfolder for each custom theme (e.g., `dracula`, `nord`, `gruvbox`, etc.). Each theme folder should contain the following files:

| File Name        | Description                                      |
|------------------|--------------------------------------------------|
| `colors.sh`      | Shell script that defines theme color variables. |
| `wallpapers.pdf` | The wallpaper to be used for the theme.          |
| `icon.txt`       | A text file containing the desired icon theme.   |

**Example directory structure:**

```
~/.config/nisfere/themes/dracula/ ├── colors.sh ├── wallpapers.pdf └── icon.txt
```

> 🔁 You can switch themes using the `change-theme.sh` script found in the `~/.nisfere/scripts/` directory.

> The colors are applied to Alacritty, Gtk theme, Bpytop, Hyprland colors, VSCode, Swaylock, Nisfere Panel
---

### 📌 Panel Configuration

The panel is controlled via a JSON config file located at:

```
~/.config/nisfere/panel-config.json
```

This file lets you customize:
- Default settings
- Bar settings
- Dock settings
- Font size & family & border

---

## 📦 What gets installed?

### Pacman Packages
Essential utilities and dependencies for the Nisfere setup:

```
fastfetch, bpytop ,code, pipewire, playerctl, networkmanager, brightnessctl, 
pkgconf, wf-recorder, thunar, thunar-archive-plugin, xarchiver, zip, unzip, 
gvfs, swww, zsh, alacritty, libnotify, python, gtk3, cairo, gtk-layer-shell, 
libgirepository, gobject-introspection, gobject-introspection-runtime, 
python-pip, python-gobject, python-psutil, python-cairo, python-dbus, 
python-pydbus, python-loguru, python-setproctitle, grim, swappy
```

### AUR Packages
These will be installed via `yay`:

```
python-fabric, swaylock-effects-git, swayidle, gnome-bluetooth-3.0, 
fabric-cli-git, slurp, imagemagick
```

---

## 🎨 Themes, Fonts, Icons
- Fonts copied to `~/.fonts`
- GTK themes to `~/.themes`
- Icons to `~/.icons`
- Cursor set to `Breeze-Adapta-Cursor`

---

## 🧠 Panel Notes
Nisfere's panel is powered by [Fabric](https://github.com/Fabric-Development/fabric). Please ensure it's installed and accessible from your system PATH.

Panel config is stored in:
```
~/.config/nisfere/panel-config.json
```

---


## ⌨️ Hyprland Default Keybindings

### General Actions

| Keybind               | Action                                            |
|----------------------|---------------------------------------------------|
| SUPER + Return       | Open terminal                                     |
| SUPER + Q            | Kill active window                                |
| SUPER + R            | Restart Nisfere panel                             |
| SUPER + M            | Exit Hyprland                                     |
| SUPER + E            | Open file manager                                 |
| SUPER + V            | Open Firefox                                      |
| SUPER + X            | Open power menu via panel                         |
| SUPER + T            | Open theme switcher via panel                     |
| SUPER + SPACE        | Open launcher/menu                                |
| SUPER + F            | Toggle fullscreen                                 |
| SUPER + S            | Toggle floating                                   |

### Focus & Resize

| Keybind                       | Action                                      |
|------------------------------|---------------------------------------------|
| SUPER + Arrow Keys           | Move focus                                   |
| SUPER + SHIFT + Arrows       | Resize active window                         |
| SUPER + P                    | Toggle pseudo-mode (dwindle)                 |
| SUPER + J                    | Toggle split (dwindle)                       |

### Workspaces

| Keybind                     | Action                                        |
|----------------------------|-----------------------------------------------|
| SUPER + [1-0]              | Switch to workspace 1–10                      |
| SUPER + SHIFT + [1-0]      | Move active window to workspace 1–10         |
| SUPER + Tab                | Next workspace                                |
| SUPER + SHIFT + Tab        | Previous workspace                            |

### Special Workspace

| Keybind                | Action                                          |
|------------------------|-------------------------------------------------|
| SUPER + S              | Toggle scratchpad                               |
| SUPER + SHIFT + S      | Move window to scratchpad                       |

### Mouse & Movement

| Keybind                | Action                                          |
|------------------------|-------------------------------------------------|
| SUPER + Mouse Down     | Next workspace                                  |
| SUPER + Mouse Up       | Previous workspace                              |
| SUPER + LMB            | Move window                                     |
| SUPER + RMB            | Resize window                                   |

### Multimedia Keys

| Keybind                         | Action                                    |
|--------------------------------|-------------------------------------------|
| XF86AudioRaiseVolume           | Increase volume                           |
| XF86AudioLowerVolume           | Decrease volume                           |
| XF86AudioMute                  | Toggle mute                               |
| XF86AudioMicMute               | Toggle microphone mute                    |
| XF86MonBrightnessUp            | Increase brightness                       |
| XF86MonBrightnessDown          | Decrease brightness                       |
| XF86Lock                       | Lock screen                               |

### Media Playback

| Keybind        | Action                    |
|----------------|---------------------------|
| XF86AudioNext  | Next track (playerctl)    |
| XF86AudioPause | Play/pause (playerctl)    |
| XF86AudioPrev  | Previous track (playerctl)|
| F3/F2/F4       | Volume control            |
| F8/F7/F6       | Media playback control    |

---

## 📁 Folder Structure

- `~/.nisfere`: Nisfere's internal files
- `~/.config/nisfere`: Configuration and themes
- `~/.cache/nisfere`: Panel notifications cache
- `~/Pictures/screenshots`: Screenshot save folder
- `~/Videos/records`: Screen recordings save folder

---

## 📜 License
MIT License

