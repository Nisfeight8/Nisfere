pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.core
import "widgets"

Item {
    id: root
    property real uiScale: 1.0

    property int _readyCount: 0
    readonly property bool _allReady: _readyCount >= 4

    // Both genuinely bottom-up now, same philosophy as Weather.qml —
    // no more fixed-constant fallback for width, no ratio split.
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 10 * root.uiScale
        opacity: root._allReady ? 1 : 0
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        ColumnLayout {
            id: leftColumn
            Layout.fillHeight: true
            Layout.fillWidth: true

            Loader {
                id: clockLoader
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: item?.implicitWidth ?? (300 * root.uiScale)
                Layout.preferredHeight: item?.implicitHeight ?? (450 * root.uiScale)
                asynchronous: true
                sourceComponent: Component {
                    MiniClock {
                        uiScale: root.uiScale
                    }
                }
                onLoaded: root._readyCount++
            }
        }
        ColumnLayout {
            id: rightColumn
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(weatherLoader.item?.implicitWidth ?? 0, mediaLoader.item?.implicitWidth ?? 0, sysInfoLoader.item?.implicitWidth ?? 0, 330 * root.uiScale)
            spacing: 10 * root.uiScale

            Loader {
                id: weatherLoader
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: Component {
                    MiniWeather {
                        uiScale: root.uiScale
                    }
                }
                onLoaded: root._readyCount++
            }
            Loader {
                id: mediaLoader
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: Component {
                    MiniMedia {
                        uiScale: root.uiScale
                    }
                }
                onLoaded: root._readyCount++
            }
            Loader {
                id: sysInfoLoader
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: Component {
                    SystemInfoDetails {
                        uiScale: root.uiScale
                    }
                }
                onLoaded: root._readyCount++
            }
        }
    }
}
