pragma Singleton
import QtQuick
import qs.core

QtObject {
    readonly property var appMap: {
        "firefox": "󰈹",
        "microsoft-edge": "󰇩",
        "discord": "",
        "vesktop": "",
        "org.kde.dolphin": "",
        "plex": "󰚺",
        "steam": "",
        "spotify": "󰓇",
        "spotube": "󰓇",
        "ristretto": "󰋩",
        "obsidian": "󱓧",
        "google-chrome": "",
        "brave-browser": "󰖟",
        "chromium": "",
        "opera": "",
        "vivaldi": "󰖟",
        "waterfox": "󰖟",
        "zen": "󰖟",
        "thorium": "󰖟",
        "tor-browser": "",
        "floorp": "󰈹",
        "gnome-terminal": "",
        "kitty": "󰄛",
        "konsole": "",
        "alacritty": "",
        "wezterm": "",
        "foot": "󰽒",
        "tilix": "",
        "xterm": "",
        "urxvt": "",
        "st": "",
        "com.mitchellh.ghostty": "󰊠",
        "code": "󰨞",
        "code-oss": "󰨞",
        "sublime-text": "",
        "atom": "",
        "android-studio": "󰀴",
        "intellij-idea": "",
        "pycharm": "󱃖",
        "webstorm": "󱃖",
        "phpstorm": "󱃖",
        "eclipse": "",
        "netbeans": "",
        "docker": "",
        "vim": "",
        "neovim": "",
        "neovide": "",
        "emacs": "",
        "slack": "󰒱",
        "telegram-desktop": "",
        "org.telegram.desktop": "",
        "whatsapp": "󰖣",
        "teams": "󰊻",
        "skype": "󰒯",
        "thunderbird": "",
        "nautilus": "󰝰",
        "thunar": "󰝰",
        "pcmanfm": "󰝰",
        "nemo": "󰝰",
        "ranger": "󰝰",
        "doublecmd": "󰝰",
        "krusader": "󰝰",
        "vlc": "󰕼",
        "mpv": "",
        "rhythmbox": "󰓃",
        "gimp": "",
        "inkscape": "",
        "krita": "",
        "blender": "󰂫",
        "kdenlive": "",
        "lutris": "󰺵",
        "heroic": "󰺵",
        "minecraft": "󰍳",
        "csgo": "󰺵",
        "dota2": "󰺵",
        "evernote": "",
        "sioyek": "",
        "dropbox": "󰇣",
        "desktop": "󰇄"
    }
    readonly property string fallback: "󰣆"
    readonly property var weatherFallback: ({
            icon: "sun",
            color: "#a6adc8"
        })

    readonly property var weatherMap: {
        "0": {
            icon: "sun",
            color: Theme.color3
        },
        "1": {
            icon: "sun",
            color: Theme.color3
        },
        "2": {
            icon: "cloud-sun",
            color: Theme.color7
        },
        "3": {
            icon: "cloud",
            color: Theme.color7
        },
        "45": {
            icon: "cloud-fog",
            color: Theme.foregroundAlt
        },
        "48": {
            icon: "cloud-fog",
            color: Theme.foregroundAlt
        },
        "51": {
            icon: "cloud-rain",
            color: Theme.color4
        },
        "53": {
            icon: "cloud-rain",
            color: Theme.color4
        },
        "55": {
            icon: "cloud-rain",
            color: Theme.color4
        },
        "61": {
            icon: "cloud-rain",
            color: Theme.color6
        },
        "63": {
            icon: "cloud-rain",
            color: Theme.color6
        },
        "65": {
            icon: "cloud-rain",
            color: Theme.color6
        },
        "71": {
            icon: "snowflake",
            color: Theme.foreground
        },
        "73": {
            icon: "snowflake",
            color: Theme.foreground
        },
        "75": {
            icon: "snowflake",
            color: Theme.foreground
        },
        "95": {
            icon: "cloud-lightning",
            color: Theme.color13
        }
    }

    function getAppIcon(appClass) {
        if (!appClass)
            return fallback;

        let c = appClass.toLowerCase();
        for (let key in appMap) {
            if (c.includes(key))
                return appMap[key];
        }
        return fallback;
    }
    function getPlayerIcon(player) {
        if (!player)
            return fallback;

        const identity = (player.identity || "").toLowerCase();

        const playerMap = {
            "spotify": "spotify",
            "firefox": "firefox",
            "mozilla firefox": "firefox",
            "chromium": "chromium",
            "google chrome": "google-chrome",
            "brave": "brave-browser",
            "edge": "microsoft-edge",
            "vlc media player": "vlc",
            "vlc": "vlc",
            "mpv": "mpv",
            "plexamp": "plex",
            "spotube": "spotube",
            "youtube music": "google-chrome"
        };

        if (identity in playerMap)
            return getAppIcon(playerMap[identity]);

        return getAppIcon(identity);
    }
    function getWeatherInfo(code, isDay) {
        let c = String(code);

        if (!isDay) {
            if (c === "0" || c === "1")
                return {
                    icon: "moon",
                    color: Theme.foreground
                };
            if (c === "2")
                return {
                    icon: "cloud-moon",
                    color: Theme.color7
                };
        }

        if (c in weatherMap) {
            return weatherMap[c];
        }

        let numericCode = parseInt(code);
        if (numericCode >= 51 && numericCode <= 67)
            return {
                icon: "cloud-rain",
                color: Theme.color4
            };
        if (numericCode >= 71 && numericCode <= 77)
            return {
                icon: "snowflake",
                color: Theme.foreground
            };
        if (numericCode >= 95)
            return {
                icon: "cloud-lightning",
                color: Theme.color13
            };

        return weatherFallback;
    }

    function getBatteryIcon(level, charging) {
        if (charging)
            return "battery-charging";

        if (level >= 80)
            return "battery-full";

        if (level >= 40)
            return "battery-medium";

        if (level >= 15)
            return "battery-low";

        return "battery-warning";
    }
    function getWifiItemIcon(s) {
        if (s > 0.8)
            return "wifi-high";
        if (s > 0.4)
            return "wifi";
        if (s > 0.1)
            return "wifi-low";
        return "wifi-off";
    }

    function getWifiIcon(isEnabled, isConnected, signalStrength) {
        if (isConnected) {
            return getWifiItemIcon(signalStrength);
        }
        if (isEnabled) {
            return "wifi";
        }
        return "wifi-off";
    }
    function getWifiActionIcon(isExpanded, isConnected) {
        if (isExpanded || isConnected)
            return "x";

        return "check";
    }
    function getVolumeIcon(volume, muted) {
        if (muted)
            return "volume-x";
        if (volume > 0.6)
            return "volume-2";
        if (volume > 0.2)
            return "volume-1";
        return "volume";
    }
    function getPlayPauseIcon(isPlaying) {
        return isPlaying ? "pause" : "play";
    }
    function getDndIcon(dndEnabled) {
        return dndEnabled ? "bell-off" : "bell";
    }
    function getBluetoothIcon(isEnabled, isConnected) {
        if (!isEnabled)
            return "bluetooth-off";
        if (isConnected)
            return "bluetooth";
        return "bluetooth-searching";
    }
    function getMicIcon(muted) {
        return muted ? "mic-off" : "mic";
    }
}
