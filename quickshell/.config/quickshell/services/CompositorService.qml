import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    readonly property var workspaces: Hyprland.workspaces.values
    readonly property var activeWindow: Hyprland.activeToplevel
    readonly property var windows: Hyprland.toplevels.values

    Component.onCompleted: Hyprland.refreshMonitors()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial" || event.name === "activespecialv2")
                Hyprland.refreshMonitors()
        }
    }

    function toggleSpecialWorkspace(name) {
        const specialName = name === "special" ? "" : name.slice("special:".length)
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.workspace.toggle_special(" + JSON.stringify(specialName) + ")")
        else
            Hyprland.dispatch("togglespecialworkspace " + specialName)
    }

    function monitorFor(screen) {
        return Hyprland.monitorFor(screen)
    }

    function focusWorkspace(selector) {
        if (Hyprland.usingLua) {
            const value = typeof selector === "number"
                ? selector.toString()
                : "\"" + selector + "\""
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + value + " })")
        } else {
            Hyprland.dispatch("workspace " + selector)
        }
    }
}
