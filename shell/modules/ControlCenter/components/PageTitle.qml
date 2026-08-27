import QtQuick
import qs.core

Text {
    property real uiScale: 1.0
    color: Theme.foreground
    font.family: Theme.fontName
    font.pixelSize: 18 * uiScale
    font.bold: true
}