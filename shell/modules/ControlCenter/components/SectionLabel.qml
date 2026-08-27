import QtQuick
import qs.core

Text {
    id: root
    property real uiScale: 1.0
    color: Theme.foreground
    font.family: Theme.fontName
    font.pixelSize: 11 * uiScale
    font.bold: true
    opacity: 0.5
}