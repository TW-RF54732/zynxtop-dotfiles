import QtQuick

QtObject {
    id: root
    required property CompositorService compositor
    required property var screen

    readonly property var monitor: compositor.monitorFor(screen)
    readonly property int activeWorkspaceId: monitor && monitor.activeWorkspace
        ? monitor.activeWorkspace.id : -1
    readonly property int specialWorkspaceId: monitor && monitor.lastIpcObject.specialWorkspace
        ? monitor.lastIpcObject.specialWorkspace.id : 0
    readonly property var workspaces: {
        const items = compositor.workspaces.filter(workspace =>
            (workspace.id > 0 || root.isSpecialWorkspace(workspace))
                && workspace.monitor === root.monitor)
        items.sort((left, right) => {
            const leftSpecial = root.isSpecialWorkspace(left)
            const rightSpecial = root.isSpecialWorkspace(right)
            if (leftSpecial !== rightSpecial)
                return leftSpecial ? 1 : -1
            return left.id - right.id
        })
        return items
    }
    readonly property var visibleWorkspaces: specialWorkspaceId !== 0
        ? workspaces.filter(workspace => root.isSpecialWorkspace(workspace)
            && workspace.id === root.specialWorkspaceId)
        : workspaces.filter(workspace => !root.isSpecialWorkspace(workspace))
    readonly property string title: compositor.activeWindow !== null
        && compositor.activeWindow.monitor === monitor ? compositor.activeWindow.title : ""

    function focusWorkspace(selector) { compositor.focusWorkspace(selector) }
    function isSpecialWorkspace(workspace) {
        return workspace.name === "special" || workspace.name.startsWith("special:")
    }
    function workspaceActive(workspace) {
        return isSpecialWorkspace(workspace)
            ? workspace.id === specialWorkspaceId
            : specialWorkspaceId === 0 && workspace.focused
    }
    function activateWorkspace(workspace) {
        if (isSpecialWorkspace(workspace))
            compositor.toggleSpecialWorkspace(workspace.name)
        else
            focusWorkspace(workspace.id)
    }
    function stepWorkspace(direction) { compositor.focusWorkspace(direction > 0 ? "e+1" : "e-1") }
}
