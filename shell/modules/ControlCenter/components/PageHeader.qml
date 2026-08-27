import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    property string title: ""
    property real uiScale: 1.0
    signal backRequested

    default property alias trailingData: trailingRow.data

    spacing: 10 * root.uiScale

    IconButton {
        icon: "chevron-left"
        size: 32 * root.uiScale
        iconSize: 18 * root.uiScale
        normalColor: Theme.backgroundAlt
        onTapped: root.backRequested()
    }

    PageTitle {
        Layout.fillWidth: true
        text: root.title
        elide: Text.ElideRight
        uiScale: root.uiScale
    }

    RowLayout {
        id: trailingRow
        spacing: 8 * root.uiScale
    }
}
