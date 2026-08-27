import QtQuick
import QtQuick.Layouts
import qs.core

// Thin divider line for separating rows in info cards.
// Usage: InfoDivider {}
Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 1
    color: Theme.borderColor
    opacity: 0.5
}
