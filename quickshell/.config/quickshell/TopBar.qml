pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "topbar"

Scope {
    id: root

    property bool dashboardOpen: false

    Style { id: style }

    IpcHandler {
        target: "topbar"
        function toggleDashboard(): void { root.dashboardOpen = !root.dashboardOpen }
        function closeDashboard(): void { root.dashboardOpen = false }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: barWindow
            required property var modelData

            readonly property var monitor: Hyprland.monitorFor(screen)
            property int lastWorkspaceId: -1

            function handleWorkspaceChange() {
                const workspace = monitor ? monitor.activeWorkspace : null
                if (!workspace || workspace.id <= 0)
                    return

                const nextId = workspace.id
                if (lastWorkspaceId < 0) {
                    lastWorkspaceId = nextId
                    return
                }
                if (nextId === lastWorkspaceId)
                    return

                surface.showWorkspaceSweep(nextId < lastWorkspaceId)
                lastWorkspaceId = nextId
            }

            Component.onCompleted: handleWorkspaceChange()

            Connections {
                target: barWindow.monitor
                function onActiveWorkspaceChanged() { barWindow.handleWorkspaceChange() }
            }

            screen: modelData
            implicitHeight: style.topBar.windowHeight
            anchors { top: true; left: true; right: true }
            exclusiveZone: style.topBar.windowHeight
            focusable: false
            color: "transparent"
            WlrLayershell.namespace: "quickshell-topbar"

            Rectangle {
                id: surface

                function showWorkspaceSweep(towardRight) {
                    workspaceSweep.stop()
                    workspaceSweepLine.x = towardRight
                        ? -workspaceSweepLine.width
                        : surface.width
                    workspaceSweepLine.opacity = 1
                    workspaceSweep.to = towardRight
                        ? surface.width
                        : -workspaceSweepLine.width
                    workspaceSweep.restart()
                }

                anchors {
                    top: parent.top
                    topMargin: style.topBar.topMargin
                    horizontalCenter: parent.horizontalCenter
                }
                width: Math.min(parent.width - style.topBar.sideMargin * 2,
                                style.topBar.maxWidth)
                height: style.topBar.height
                radius: style.topBar.radius
                color: style.colors.topBarSurface
                border.width: style.topBar.dividerWidth
                border.color: style.colors.separator
                antialiasing: true
                clip: true

                Rectangle {
                    id: workspaceSweepLine
                    anchors.bottom: parent.bottom
                    width: parent.width * style.topBar.workspaceSweepWidth
                    height: style.topBar.workspaceSweepHeight
                    color: style.colors.textSecondary
                    opacity: 0
                    z: 2
                }

                NumberAnimation {
                    id: workspaceSweep
                    target: workspaceSweepLine
                    property: "x"
                    duration: style.topBar.workspaceSweepDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1]
                    onFinished: workspaceSweepLine.opacity = 0
                }

                Row {
                    id: leftSection
                    anchors {
                        left: parent.left
                        leftMargin: style.topBar.horizontalPadding
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: style.topBar.itemSpacing

                    Workspaces {
                        theme: style
                        monitor: barWindow.monitor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Rectangle {
                    anchors.left: leftSection.right
                    anchors.leftMargin: style.topBar.itemSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    width: style.topBar.dividerWidth
                    height: style.topBar.dividerHeight
                    color: style.colors.separator
                    visible: activeWindow.visible
                }

                ActiveWindow {
                    id: activeWindow
                    theme: style
                    monitor: barWindow.monitor
                    width: Math.max(0, parent.width - 2 * (
                        style.topBar.horizontalPadding
                        + Math.max(leftSection.width + style.topBar.dividerWidth
                                   + style.topBar.itemSpacing, rightSection.width)
                        + style.topBar.itemSpacing))
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        bottom: parent.bottom
                    }
                }

                Row {
                    id: rightSection
                    anchors {
                        right: parent.right
                        rightMargin: style.topBar.horizontalPadding
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: style.topBar.itemSpacing

                    Clock {
                        theme: style
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: style.topBar.dividerWidth
                        height: style.topBar.dividerHeight
                        color: style.colors.separator
                    }

                    StatusIndicators {
                        theme: style
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DashboardTrigger {
                        theme: style
                        active: root.dashboardOpen
                        anchors.verticalCenter: parent.verticalCenter
                        onToggled: root.dashboardOpen = !root.dashboardOpen
                    }
                }
            }
        }
    }
}
