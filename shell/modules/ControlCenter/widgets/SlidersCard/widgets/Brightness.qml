import QtQuick
import qs.services
import qs.core

SliderRow {
    activeIcon: "sun"

    value: BrightnessService.percentage
    visible: BrightnessService.isAvailable
    isMuteable: false

    onFinalValueChanged: newValue => BrightnessService.setPercentage(newValue)
}
