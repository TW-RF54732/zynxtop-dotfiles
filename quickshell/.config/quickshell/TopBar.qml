pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "topbar"
import "components"
import "services"
import "notifications"

Scope {
    id: root

    property bool dashboardOpen: false

    required property var theme
    required property CompositorService compositor
    required property AudioService audio
    required property NetworkService network
    required property ClockService clock
    required property NotificationService notifications
    SystemStatsService { id: systemStats; enabled: root.dashboardOpen }

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
            readonly property real normalBarWidth: Math.min(width - root.theme.topBar.sideMargin * 2,
                root.theme.topBar.maxWidth)
            readonly property real normalRightSpace: (width - normalBarWidth) / 2
                - root.theme.topBar.sideMargin - root.theme.notifications.gap
            readonly property real notificationReserve: root.notifications.notifications.length > 0
                ? Math.min(Math.max(0, normalBarWidth - Math.max(320,
                    leftSection.width + rightSection.width + root.theme.topBar.horizontalPadding * 2
                    + root.theme.topBar.itemSpacing * 4)),
                    Math.max(0, root.theme.notifications.laneWidth - normalRightSpace)) : 0
            readonly property real dashboardHeight: Math.min(root.theme.dashboard.height,
                Math.max(0, screen.height - root.theme.topBar.windowHeight
                    - root.theme.topBar.topMargin - root.theme.dashboard.gap))
            property real dashboardReveal: root.dashboardOpen ? dashboardHeight : 0

            Behavior on dashboardReveal {
                NumberAnimation {
                    duration: root.theme.dashboard.animationDuration
                    easing.type: Easing.InOutCubic
                }
            }

            readonly property real dashboardOffset: dashboardReveal
                + (dashboardHeight > 0 ? root.theme.dashboard.gap * dashboardReveal / dashboardHeight : 0)
            // Keep the Wayland surface stable; animate only the panel position.
            implicitHeight: root.theme.topBar.windowHeight + dashboardHeight + root.theme.dashboard.gap
                + root.theme.notifications.detailMaxHeight
            mask: Region {
                width: barWindow.width
                height: root.theme.topBar.windowHeight + barWindow.dashboardOffset
                Region {
                    x: notificationStrip.x + notificationStrip.detailBounds.left
                    y: notificationStrip.y + notificationStrip.height
                    width: notificationStrip.detailBounds.width
                    height: notificationStrip.visible ? notificationStrip.detailBounds.extra : 0
                }
            }
            anchors { top: true; left: true; right: true }
            exclusiveZone: root.theme.topBar.windowHeight
            focusable: false
            color: "transparent"
            WlrLayershell.namespace: "quickshell-topbar"

            Item {
                anchors {
                    top: parent.top
                    topMargin: root.theme.topBar.topMargin
                    horizontalCenter: parent.horizontalCenter
                    horizontalCenterOffset: -barWindow.notificationReserve / 2
                }
                width: surface.width
                height: barWindow.dashboardHeight
                clip: true
                visible: barWindow.dashboardReveal > 0

                Dashboard {
                    theme: root.theme
                    systemStats: systemStats
                    audio: root.audio
                    network: root.network
                    width: parent.width
                    height: barWindow.dashboardHeight
                    y: barWindow.dashboardReveal - height
                }
            }

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
                    topMargin: root.theme.topBar.topMargin + barWindow.dashboardOffset
                    horizontalCenter: parent.horizontalCenter
                    horizontalCenterOffset: -barWindow.notificationReserve / 2
                }
                width: barWindow.normalBarWidth - barWindow.notificationReserve
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
                    activeWindow: monitorContext.activeWindow
                    windows: root.compositor.windows
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

            NotificationStrip {
                id: notificationStrip
                theme: root.theme
                notifications: root.notifications.notifications
                x: surface.x + surface.width + root.theme.notifications.gap
                y: surface.y
                width: Math.max(0, barWindow.width - root.theme.topBar.sideMargin - x)
                height: surface.height
                screenRight: barWindow.width - x
                detailMaxHeight: Math.max(0, Math.min(root.theme.notifications.detailMaxHeight,
                    barWindow.screen.height - y - height - root.theme.topBar.sideMargin))
                onActivated: notification => root.notifications.activate(notification)
                onDismissed: notification => notification.dismiss()
            }
        }
    }
}
