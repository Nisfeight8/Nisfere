import QtQuick
import qs.core
import qs.services

ControlButton {
    id: root

    iconText: "keyboard"
    title: KeyboardService.getFull(KeyboardService.currentLayout)
    subtitle: "Layout: " + KeyboardService.getShort(KeyboardService.currentLayout)

    isActive: KeyboardService.currentLayout !== "us" && KeyboardService.currentLayout !== "en"

    onClicked: {
        let layouts = KeyboardService.availableLayouts;
        if (layouts.length < 2)
            return; // Failsafe

        KeyboardService.toggleLayout();
    }
}
