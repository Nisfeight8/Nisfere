import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

GlassCard {
    id: miniWeatherCard
    property real uiScale: 1.0

    readonly property var weatherVisuals: Icons.getWeatherInfo(WeatherService.weatherCode, WeatherService.isDay)

    // Preferred width this card wants — independent of its own actual
    // rendered size, same reasoning as MiniClock.baseCardHeight (see
    // that file's comment): rightColumn now reads this to decide its
    // own width, so this must NOT be derived from miniWeatherCard's
    // own width/height or it'd be circular.
    readonly property real baseCardWidth: 280
    implicitWidth: baseCardWidth * uiScale

    anchors.fill: parent
    clip: true

    readonly property real refSize: Math.min(miniWeatherCard.width, miniWeatherCard.height)

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        // anchors.margins: 10 * miniWeatherCard.uiScale
        spacing: 2 * miniWeatherCard.uiScale

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.max(5, miniWeatherCard.refSize * 0.08)

            LucideIcon {
                id: weatherIcon
                Layout.alignment: Qt.AlignVCenter
                color: miniWeatherCard.weatherVisuals.color
                icon: miniWeatherCard.weatherVisuals.icon
                size: Math.max(24, miniWeatherCard.refSize * 0.35)
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(18, miniWeatherCard.refSize * 0.28)
                text: WeatherService.ready ? Math.round(WeatherService.temperature) + "°C" : "--°C"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.foreground
            opacity: 0.1
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            spacing: 2 * miniWeatherCard.uiScale

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(12, miniWeatherCard.refSize * 0.15)
                text: WeatherService.ready ? WeatherService.city : "Loading..."
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: Math.max(10, miniWeatherCard.refSize * 0.10)
                opacity: 0.6
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: WeatherService.ready ? WeatherService.description : ""
            }
        }
    }
}
