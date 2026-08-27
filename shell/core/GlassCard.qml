import QtQuick
import qs.core

Item {
    id: root

    default property alias content: container.data

    GlassBackground {
    }
    Item {
        id: container

        anchors.fill: parent
    }
}
