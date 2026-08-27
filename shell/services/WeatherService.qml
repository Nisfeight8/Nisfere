pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property string city: ""
    property var dailyForecast: []
    property string description: ""
    property string error: ""
    property real feelsLike: 0
    property int humidity: 0
    property bool isDay: true
    property bool loading: false
    property string location: ""
    property bool ready: false
    readonly property int refreshInterval: 60 * 60 * 1000
    // Was gated on `root.ready` — meant that if the very first update()
    // ever failed (or hung with no timeout, see below), `ready` never
    // became true, so this timer never started, and the service was
    // stuck forever with no way to recover without a manual restart.
    // Now always running, so a successful refresh always gets
    // scheduled regardless of how earlier attempts went.
    property Timer refreshTimer: Timer {
        interval: root.refreshInterval
        repeat: true
        running: true

        onTriggered: root.update()
    }
    // New: short-interval retry specifically for the "still broken"
    // case — only active while there's an error and we're not ready
    // yet, so a hung/failed first attempt gets retried in 30s instead
    // of waiting up to a full hour for refreshTimer.
    property Timer retryTimer: Timer {
        interval: 30 * 1000
        repeat: true
        running: root.error !== "" && !root.ready

        onTriggered: root.update()
    }
    property real temperature: 0
    // How long an individual request is allowed to hang before we
    // treat it as failed. Neither xhr below had this before — with no
    // timeout, a request that never reaches readyState DONE (e.g. DNS
    // not up yet right after boot, no route to host) just hangs
    // forever: onreadystatechange never fires, loading never clears,
    // ready never becomes true, and (before the fix above) the retry
    // timer never even started. This is what caused the "stuck on
    // loading if Weather is the first tab opened" bug.
    readonly property int requestTimeoutMs: 10000
    property int weatherCode: 0
    readonly property var weatherMap: {
        0: "Clear",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Fog",
        51: "Drizzle",
        53: "Drizzle",
        55: "Drizzle",
        56: "Freezing drizzle",
        57: "Freezing drizzle",
        61: "Light rain",
        63: "Rain",
        65: "Heavy rain",
        66: "Freezing rain",
        67: "Freezing rain",
        71: "Light snow",
        73: "Snow",
        75: "Heavy snow",
        77: "Snow grains",
        80: "Rain showers",
        81: "Heavy rain showers",
        82: "Violent rain showers",
        85: "Snow showers",
        86: "Heavy snow showers",
        95: "Thunderstorm",
        96: "Thunderstorm with hail",
        99: "Thunderstorm with hail"
    }
    property real windSpeed: 0

    function fetchLocation() {
        const xhr = new XMLHttpRequest();

        xhr.open("GET", "http://ip-api.com/json/");
        xhr.timeout = root.requestTimeoutMs;

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                console.error("ERROR fetching location");
                root.loading = false;
                root.error = "Failed to fetch location";
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);

                if (data.status !== "success") {
                    root.loading = false;
                    root.error = data.message || "Location lookup failed";
                    return;
                }

                if (!data.lat || !data.lon) {
                    root.loading = false;
                    root.error = "No coordinates received";
                    return;
                }

                root.city = data.city || "Unknown";
                root.location = `${data.lat},${data.lon}`;

                root.fetchWeather();
            } catch (e) {
                console.error("Location Parse Error:", e);
                root.loading = false;
                root.error = "Invalid location response";
            }
        };

        // Without this, a hung request (no network yet, DNS not up,
        // etc.) never reaches DONE, so onreadystatechange never runs,
        // loading/error never update, and — before the timer fix above
        // — nothing would ever retry.
        xhr.ontimeout = function () {
            console.error("Location request timed out");
            root.loading = false;
            root.error = "Location request timed out";
        };
        xhr.onerror = function () {
            console.error("Location request failed");
            root.loading = false;
            root.error = "Failed to fetch location";
        };

        xhr.send();
    }
    function fetchWeather() {
        const parts = root.location.split(",");

        if (parts.length !== 2) {
            root.loading = false;
            root.error = "Invalid coordinates";
            return;
        }

        const lat = parts[0].trim();
        const lon = parts[1].trim();

        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=7`;
        const xhr = new XMLHttpRequest();

        xhr.open("GET", url);
        xhr.timeout = root.requestTimeoutMs;

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            root.loading = false;

            if (xhr.status !== 200) {
                root.error = "Failed to fetch weather";
                return;
            }

            try {
                const json = JSON.parse(xhr.responseText);

                if (!json.current) {
                    root.error = "No weather data";
                    return;
                }

                root.temperature = json.current.temperature_2m;
                root.weatherCode = json.current.weather_code;
                root.feelsLike = json.current.apparent_temperature;
                root.humidity = json.current.relative_humidity_2m;
                root.windSpeed = json.current.wind_speed_10m;
                root.isDay = json.current.is_day === 1;

                root.description = root.weatherMap[root.weatherCode] || "Unknown";

                if (json.daily) {
                    const dailyList = [];
                    for (let i = 0; i < json.daily.time.length; i++) {
                        dailyList.push({
                            date: json.daily.time[i],
                            maxTempC: Math.round(json.daily.temperature_2m_max[i]),
                            minTempC: Math.round(json.daily.temperature_2m_min[i]),
                            weatherCode: json.daily.weather_code[i]
                        });
                    }
                    root.dailyForecast = dailyList;
                }

                root.ready = true;
                root.error = "";
            } catch (e) {
                console.error("Weather Parse Error:", e);
                root.error = "Invalid weather response";
            }
        };

        xhr.ontimeout = function () {
            console.error("Weather request timed out");
            root.loading = false;
            root.error = "Weather request timed out";
        };
        xhr.onerror = function () {
            console.error("Weather request failed");
            root.loading = false;
            root.error = "Failed to fetch weather";
        };

        xhr.send();
    }
    function update() {
        root.error = "";
        root.loading = true;

        if (root.location === "") {
            root.fetchLocation();
        } else {
            root.fetchWeather();
        }
    }

    Component.onCompleted: {
        root.update();
    }
}
