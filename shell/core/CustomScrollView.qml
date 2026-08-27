// core/CustomScrollView.qml
import QtQuick
import QtQuick.Controls
import qs.core

Flickable {
    id: root

    default property alias content: contentItem.data
    property real uiScale: 1.0
    property color handleColor: Theme.foreground
    property color handleHoverColor: Theme.selected

    contentWidth: contentItem.implicitWidth
    contentHeight: contentItem.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    clip: true

    Item {
        id: contentItem
        width: root.width
        implicitHeight: childrenRect.height
    }

    ScrollBar.vertical: CustomScrollBar {
        uiScale: root.uiScale
        handleColor: root.handleColor
        handleHoverColor: root.handleHoverColor
    }
}
