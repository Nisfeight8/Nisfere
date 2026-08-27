import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    anchors.fill: parent
    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    function getDayName(dateString, index) {
        if (index === 0)
            return "Today";
        if (index === 1)
            return "Tomorrow";
        const date = new Date(dateString);
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        return days[date.getDay()];
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 15 * root.uiScale

        RowLayout {
            id: topRow

            Layout.fillWidth: true
            spacing: 10 * root.uiScale

            ColumnLayout {
                spacing: 10 * root.uiScale

                GlassCard {
                    id: mainWeatherCard

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: weatherRow.implicitWidth + (40 * root.uiScale)
                    implicitHeight: weatherRow.implicitHeight + (40 * root.uiScale)

                    RowLayout {
                        id: weatherRow

                        readonly property var visuals: Icons.getWeatherInfo(WeatherService.weatherCode, WeatherService.isDay)

                        anchors.centerIn: parent
                        spacing: 10 * root.uiScale

                        LucideIcon {
                            color: weatherRow.visuals.color
                            size: 60 * root.uiScale
                            icon: weatherRow.visuals.icon
                        }
                        ColumnLayout {
                            spacing: 5 * root.uiScale

                            Text {
                                color: Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 32 * root.uiScale
                                text: WeatherService.ready ? Math.round(WeatherService.temperature) + "°C" : "--°C"
                            }
                            Text {
                                color: Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 18 * root.uiScale
                                text: WeatherService.ready ? WeatherService.city : "Loading..."
                            }
                            Text {
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 16 * root.uiScale
                                opacity: 0.7
                                text: WeatherService.ready ? WeatherService.description : ""
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 10 * root.uiScale

                GlassCard {
                    id: feelsLikeCard

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: feelsLikeRow.implicitWidth + (30 * root.uiScale)
                    implicitHeight: feelsLikeRow.implicitHeight + (30 * root.uiScale)

                    RowLayout {
                        id: feelsLikeRow

                        anchors.left: parent.left
                        anchors.margins: 15 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5 * root.uiScale

                        LucideIcon {
                            size: 20 * root.uiScale
                            color: Theme.color1
                            icon: "flame"
                        }
                        Text {
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            opacity: 0.8
                            text: "Feels Like\n" + (WeatherService.ready ? Math.round(WeatherService.feelsLike) + "°C" : "--")
                        }
                    }
                }
                GlassCard {
                    id: humidityCard

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: humidityRow.implicitWidth + (30 * root.uiScale)
                    implicitHeight: humidityRow.implicitHeight + (30 * root.uiScale)

                    RowLayout {
                        id: humidityRow

                        anchors.left: parent.left
                        anchors.leftMargin: 15 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5 * root.uiScale

                        LucideIcon {
                            color: Theme.color6
                            size: 20 * root.uiScale
                            icon: "droplets"
                        }
                        Text {
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            opacity: 0.8
                            text: "Humidity\n" + (WeatherService.ready ? WeatherService.humidity + "%" : "--")
                        }
                    }
                }
                GlassCard {
                    id: windCard

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: windRow.implicitWidth + (30 * root.uiScale)
                    implicitHeight: windRow.implicitHeight + (30 * root.uiScale)

                    RowLayout {
                        id: windRow

                        anchors.left: parent.left
                        anchors.leftMargin: 15 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5 * root.uiScale

                        LucideIcon {
                            color: Theme.color2
                            size: 20 * root.uiScale
                            icon: "wind"
                        }
                        Text {
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            opacity: 0.8
                            text: "Wind\n" + (WeatherService.ready ? Math.round(WeatherService.windSpeed) + " km/h" : "--")
                        }
                    }
                }
            }
        }

        GlassCard {
            Layout.fillWidth: true
            implicitHeight: forecastTitleText.implicitHeight + (24 * root.uiScale)

            Text {
                id: forecastTitleText

                anchors.left: parent.left
                anchors.leftMargin: 16 * root.uiScale
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 18 * root.uiScale
                text: "7-Day Forecast"
            }
        }

        RowLayout {
            id: forecastRow

            Layout.fillWidth: true
            spacing: 10 * root.uiScale

            Repeater {
                model: WeatherService.dailyForecast

                delegate: GlassCard {
                    id: dayCard

                    readonly property var dayVisuals: Icons.getWeatherInfo(modelData.weatherCode, true)

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: dayColumn.implicitWidth + (24 * root.uiScale)
                    implicitHeight: dayColumn.implicitHeight + (40 * root.uiScale)

                    ColumnLayout {
                        id: dayColumn

                        anchors.centerIn: parent
                        spacing: 7 * root.uiScale

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            color: index === 0 ? Theme.selected : Theme.foreground
                            font.bold: true
                            font.family: Theme.fontName
                            font.pixelSize: 13 * root.uiScale
                            opacity: index === 0 ? 1.0 : 0.8
                            text: root.getDayName(modelData.date, index)
                        }

                        LucideIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: dayCard.dayVisuals.icon
                            color: dayCard.dayVisuals.color
                            size: 40 * root.uiScale
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 5 * root.uiScale

                            Text {
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 14 * root.uiScale
                                opacity: 0.5
                                text: modelData.minTempC + "°"
                            }
                            Text {
                                color: Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 15 * root.uiScale
                                text: modelData.maxTempC + "°"
                            }
                        }
                    }
                }
            }
        }
    }
}
