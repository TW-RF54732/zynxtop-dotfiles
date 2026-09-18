import QtQuick

QtObject {
    id: root
    required property CompositorService compositor
    required property var screen

    readonly property var monitor: compositor.monitorFor(screen)
    readonly property int activeWorkspaceId: monitor && monitor.activeWorkspace
        ? monitor.activeWorkspace.id : -1
    readonly property var workspaces: {
        const items = compositor.workspaces.filter(workspace =>
            workspace.id > 0 && workspace.monitor === root.monitor)
        items.sort((left, right) => left.id - right.id)
        return items
    }
    readonly property string title: compositor.activeWindow !== null
        && compositor.activeWindow.monitor === monitor ? compositor.activeWindow.title : ""

    function focusWorkspace(selector) { compositor.focusWorkspace(selector) }
    function stepWorkspace(direction) { compositor.focusWorkspace(direction > 0 ? "e+1" : "e-1") }
}
