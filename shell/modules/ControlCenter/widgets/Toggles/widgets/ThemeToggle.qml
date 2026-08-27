import QtQuick
import qs.core
import qs.services

ControlButton {
    id: root

    property bool isDark: ThemeState.mode === "dark"

    iconText: "palette"
    title: isDark ? "Dark Theme" : "Light Theme"
    subtitle: "Appearance"

    isActive: isDark

    onClicked: {
        ThemeActions.toggleMode();
    }
}
