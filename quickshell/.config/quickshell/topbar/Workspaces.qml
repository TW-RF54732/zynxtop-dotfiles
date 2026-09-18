pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../components"

Row {
    id: root

    required property var theme
    required property var monitor
    spacing: theme.topBar.workspaceSpacing

    readonly property var visibleWorkspaces: {
        const items = Hyprland.workspaces.values.filter(workspace =>
            workspace.id > 0 && workspace.monitor === root.monitor)
        items.sort((left, right) => left.id - right.id)
        return items
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

    Repeater {
        model: ScriptModel { values: root.visibleWorkspaces }

        delegate: Rectangle {
            id: workspaceItem
            required property var modelData

            width: root.theme.topBar.workspaceSize
            height: root.theme.topBar.workspaceSize
            radius: root.theme.geometry.cornerRadius
            color: modelData.focused ? root.theme.colors.frame : "transparent"

            Behavior on color {
                ColorAnimation { duration: root.theme.motion.fastDuration }
            }

            MonoText {
                theme: root.theme
                anchors.centerIn: parent
                text: workspaceItem.modelData.name
                tone: workspaceItem.modelData.focused
                    ? root.theme.colors.textPrimary
                    : root.theme.colors.textSecondary
                font.pixelSize: root.theme.topBar.textSize
                font.bold: workspaceItem.modelData.focused
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.focusWorkspace(workspaceItem.modelData.id)
            }
        }
    }

    WheelHandler {
        onWheel: event => {
            const direction = event.angleDelta.y > 0 ? -1 : 1
            root.focusWorkspace(direction > 0 ? "e+1" : "e-1")
        }
    }
}
