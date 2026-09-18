pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../services"
import "../components"

Row {
    id: root

    required property var theme
    required property MonitorContext context
    spacing: theme.topBar.workspaceSpacing

    Repeater {
        model: ScriptModel { values: root.context.workspaces }

        delegate: InteractiveSurface {
            id: workspaceItem
            required property var modelData

            theme: root.theme
            width: root.theme.topBar.workspaceSize
            height: root.theme.topBar.workspaceSize
            active: modelData.focused
            onClicked: root.context.focusWorkspace(modelData.id)

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


        }
    }

    WheelHandler {
        onWheel: event => {
            const direction = event.angleDelta.y > 0 ? -1 : 1
            root.context.stepWorkspace(direction)
        }
    }
}
