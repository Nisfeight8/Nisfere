// @pragma UseQApplication

import QtQuick
import Quickshell
import qs.modules.ScreenBorder
import qs.modules.PowerMenu
import qs.modules.Locker
import qs.modules.AreaPicker
import qs.modules.IpcHandlers

import qs.services
import qs.core

ShellRoot {
    id: root
    property var _internalNotif: InternalNotificationService

    IpcHandlers {}

    AreaPicker {}
    ScreenBorder {}

    LazyLoader {
        id: powerMenuLoader

        activeAsync: ShellState.powerMenuOpened
        PowerMenu {}
    }

    LazyLoader {
        id: lockerLoader
        loading: true
        activeAsync: ShellState.isLocked

        Locker {
            id: locker
            property Connections _con: Connections {
                target: ShellState

                function onIsLockedChanged() {
                    if (ShellState.isLocked) {
                        LockerService.restart();
                    } else {
                        LockerService.stop();
                    }
                }
            }
        }
    }
    property var _desktopEntryWarmup: DesktopEntryService
}
