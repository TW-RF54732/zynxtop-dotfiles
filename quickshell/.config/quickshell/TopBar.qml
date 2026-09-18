pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "topbar"
import "components"
import "services"

Scope {
    id: root

    property bool dashboardOpen: false

    required property var theme
    required property CompositorService compositor
    required property AudioService audio
    required property NetworkService network
    required property ClockService clock

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

            MonitorContext {
                id: monitorContext
                compositor: root.compositor
                screen: barWindow.screen
            }
            property int lastWorkspaceId: -1

            function handleWorkspaceChange() {
                const nextId = monitorContext.activeWorkspaceId
                if (nextId <= 0)
                    return

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
                target: monitorContext
                function onActiveWorkspaceIdChanged() { barWindow.handleWorkspaceChange() }
            }

            screen: modelData
            implicitHeight: root.theme.topBar.windowHeight
            anchors { top: true; left: true; right: true }
            exclusiveZone: root.theme.topBar.windowHeight
            focusable: false
            color: "transparent"
            WlrLayershell.namespace: "quickshell-topbar"

            GlassFrame {
                id: surface
                theme: root.theme

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
                    topMargin: root.theme.topBar.topMargin
                    horizontalCenter: parent.horizontalCenter
                }
                width: Math.min(parent.width - root.theme.topBar.sideMargin * 2,
                                root.theme.topBar.maxWidth)
                height: root.theme.topBar.height
                radius: root.theme.topBar.radius
                color: root.theme.colors.topBarSurface
                border.width: root.theme.topBar.dividerWidth
                border.color: root.theme.colors.separator
                antialiasing: true
                clip: true

                Rectangle {
                    id: workspaceSweepLine
                    anchors.bottom: parent.bottom
                    width: parent.width * root.theme.topBar.workspaceSweepWidth
                    height: root.theme.topBar.workspaceSweepHeight
                    color: root.theme.colors.textSecondary
                    opacity: 0
                    z: 2
                }

                NumberAnimation {
                    id: workspaceSweep
                    target: workspaceSweepLine
                    property: "x"
                    duration: root.theme.topBar.workspaceSweepDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1]
                    onFinished: workspaceSweepLine.opacity = 0
                }

                Row {
                    id: leftSection
                    anchors {
                        left: parent.left
                        leftMargin: root.theme.topBar.horizontalPadding
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: root.theme.topBar.itemSpacing

                    Workspaces {
                        theme: root.theme
                        context: monitorContext
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Separator {
                    theme: root.theme
                    vertical: true
                    anchors.left: leftSection.right
                    anchors.leftMargin: root.theme.topBar.itemSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.theme.topBar.dividerWidth
                    height: root.theme.topBar.dividerHeight
                    color: root.theme.colors.separator
                    visible: activeWindow.visible
                }

                ActiveWindow {
                    id: activeWindow
                    theme: root.theme
                    title: monitorContext.title
                    width: Math.max(0, parent.width - 2 * (
                        root.theme.topBar.horizontalPadding
                        + Math.max(leftSection.width + root.theme.topBar.dividerWidth
                                   + root.theme.topBar.itemSpacing, rightSection.width)
                        + root.theme.topBar.itemSpacing))
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
                        rightMargin: root.theme.topBar.horizontalPadding
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: root.theme.topBar.itemSpacing

                    Clock {
                        theme: root.theme
                        clock: root.clock
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Separator {
                        theme: root.theme
                        vertical: true
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.theme.topBar.dividerWidth
                        height: root.theme.topBar.dividerHeight
                        color: root.theme.colors.separator
                    }

                    StatusIndicators {
                        theme: root.theme
                        audio: root.audio
                        network: root.network
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DashboardTrigger {
                        theme: root.theme
                        active: root.dashboardOpen
                        anchors.verticalCenter: parent.verticalCenter
                        onToggled: root.dashboardOpen = !root.dashboardOpen
                    }
                }
            }
        }
    }
}
