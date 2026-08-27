import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core
import qs.services

BarWidget {
    id: root
    useGradient: true
    paddingX: 0
    spacing: 6
    readonly property int workspacesPerMonitor: ShellState.workspacesPerMonitor
    readonly property string screenName: QsWindow.window?.screen?.name ?? ""
    readonly property var monitorData: HyprlandData.monitors.values.find(m => m.name === screenName)
    readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.id === monitorData?.id) ?? null
    readonly property int currentWorkspaceId: monitor?.activeWorkspace?.id ?? 1
    readonly property int baseWorkspaceId: Math.floor((currentWorkspaceId - 1) / workspacesPerMonitor) * workspacesPerMonitor + 1

    Repeater {
        id: workspaces
        model: ScriptModel {
            values: Hyprland.workspaces.values.filter(ws => {
                return ws.id >= root.baseWorkspaceId && ws.id < root.baseWorkspaceId + root.workspacesPerMonitor;
            }).sort((a, b) => a.id - b.id)
        }

        delegate: WorkspaceButton {
            implicitHeight: root.height
        }
    }
}
