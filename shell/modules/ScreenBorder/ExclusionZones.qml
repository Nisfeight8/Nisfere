import Quickshell
import qs.core

// The 4 invisible windows that reserve screen space for the bar/bezels
// so other windows tile around them
// Exclusions.qml pattern (one small window per edge, each with its own
// unambiguous single-edge exclusiveZone).
Scope {
    id: root

    property var screen: null
    property real barHeight: Theme.scaledBarHeight(screen)
    property real bezelSize: Theme.screenBorderSize

    ExclusionZone {
        screen: root.screen
        anchors.top: true
        implicitHeight: root.barHeight
    }
    ExclusionZone {
        screen: root.screen
        anchors.bottom: true
        implicitHeight: root.bezelSize
    }
    ExclusionZone {
        screen: root.screen
        anchors.left: true
        implicitWidth: root.bezelSize
    }
    ExclusionZone {
        screen: root.screen
        anchors.right: true
        implicitWidth: root.bezelSize
    }

    component ExclusionZone: PanelWindow {
        color: "transparent"
        mask: Region {}   // fully click-through — pure reservation, no visuals
    }
}
