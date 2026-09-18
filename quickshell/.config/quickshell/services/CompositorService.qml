import QtQuick
import Quickshell.Hyprland

QtObject {
    readonly property var workspaces: Hyprland.workspaces.values
    readonly property var activeWindow: Hyprland.activeToplevel

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
