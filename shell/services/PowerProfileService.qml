pragma Singleton

import QtQuick
import Quickshell

import Quickshell.Services.UPower

Singleton {
    id: root

    property int currentProfile: PowerProfiles.profile
    property string degradationText: {
        if (PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature)
            return "Overheating!";
        if (PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected)
            return "Big Usage";
        return "";
    }
    property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    property bool isDegraded: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
    property string profileIcon: {
        if (currentProfile === PowerProfile.PowerSaver)
            return "leaf";
        if (currentProfile === PowerProfile.Performance)
            return "gauge";
        return "siren";
    }
    property string profileName: {
        if (currentProfile === PowerProfile.PowerSaver)
            return "Saving";
        if (currentProfile === PowerProfile.Performance)
            return "Performance";
        return "Balance";
    }

    function cycleProfile() {
        if (currentProfile === PowerProfile.PowerSaver) {
            PowerProfiles.profile = PowerProfile.Balanced;
        } else if (currentProfile === PowerProfile.Balanced) {
            if (hasPerformance) {
                PowerProfiles.profile = PowerProfile.Performance;
            } else {
                PowerProfiles.profile = PowerProfile.PowerSaver;
            }
        } else {
            PowerProfiles.profile = PowerProfile.PowerSaver;
        }
    }
}
