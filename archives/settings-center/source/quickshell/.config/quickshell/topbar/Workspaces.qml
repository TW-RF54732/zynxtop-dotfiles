pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../services"
import "../components"

Item {
    id: root

    required property var theme
    required property MonitorContext context
    implicitWidth: workspaceRow.width
    implicitHeight: theme.topBar.workspaceSize
    readonly property int selectedIndex: context.visibleWorkspaces.findIndex(
        workspace => root.context.workspaceActive(workspace))

    SelectionHighlight {
        theme: root.theme
        visible: root.selectedIndex >= 0
        targetX: Math.max(0, root.selectedIndex)
            * (root.theme.topBar.workspaceSize + root.theme.topBar.workspaceSpacing)
        targetWidth: root.theme.topBar.workspaceSize
        targetHeight: root.theme.topBar.workspaceSize
        fillColor: Qt.rgba(root.theme.colors.frame.r, root.theme.colors.frame.g,
                          root.theme.colors.frame.b, root.theme.topBar.workspaceSelectionOpacity)
    }

    Row {
        id: workspaceRow
        spacing: root.theme.topBar.workspaceSpacing

        Repeater {
            model: ScriptModel { values: root.context.visibleWorkspaces }

            delegate: InteractiveSurface {
                id: workspaceItem
                required property var modelData

                theme: root.theme
                width: root.theme.topBar.workspaceSize
                height: root.theme.topBar.workspaceSize
                active: root.context.workspaceActive(modelData)
                color: "transparent"
                onClicked: root.context.activateWorkspace(modelData)

                MonoText {
                    theme: root.theme
                    anchors.centerIn: parent
                    text: workspaceItem.modelData.name
                    visible: !root.context.isSpecialWorkspace(workspaceItem.modelData)
                    tone: workspaceItem.active
                        ? root.theme.colors.textPrimary
                        : root.theme.colors.textSecondary
                    font.pixelSize: root.theme.topBar.textSize
                    font.bold: workspaceItem.active
                }

                MonoIcon {
                    theme: root.theme
                    anchors.centerIn: parent
                    name: "star"
                    width: root.theme.topBar.iconSize
                    height: width
                    lineWidth: root.theme.topBar.iconStrokeWidth
                    visible: root.context.isSpecialWorkspace(workspaceItem.modelData)
                    color: workspaceItem.active
                        ? root.theme.colors.textPrimary
                        : root.theme.colors.textSecondary
                }

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
