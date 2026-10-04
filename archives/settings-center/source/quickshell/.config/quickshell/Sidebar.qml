pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"
import "sidebar"

Scope {
    id: root
    required property var theme
    required property var compositor
    required property var user
    required property var clock
    required property var notifications
    property list<Component> widgets: []
    function show() { controller.show(); }
    function hide() { controller.hide(); }
    function toggle() { controller.toggle(); }

    SidebarController {
        id: controller
        screens: Quickshell.screens
        focusedMonitorName: root.compositor.focusedMonitor ? root.compositor.focusedMonitor.name : ""
    }
    AnimatedVisibility {
        id: lifecycle
        requestedVisible: controller.requestedVisible
        duration: root.theme.sidebar.animationDuration
    }
    IpcHandler {
        target: "sidebar"
        function toggle(): void { root.toggle(); }
        function show(): void { root.show(); }
        function hide(): void { root.hide(); }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: window
            required property var modelData
            readonly property bool isTarget: screen === controller.targetScreen
            objectName: isTarget ? "sidebarWindow" : "sidebarBackdrop"
            screen: modelData
            visible: lifecycle.mounted
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            WlrLayershell.namespace: "quickshell-sidebar"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: isTarget && lifecycle.mounted
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Shortcut {
                sequence: "Escape"
                context: Qt.WindowShortcut
                enabled: window.isTarget && lifecycle.mounted
                onActivated: controller.hide()
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: controller.hide()
                // An outside wheel gesture must not operate the underlying app.
                onWheel: event => event.accepted = true
            }
            GlassFrame {
                id: panel
                objectName: "sidebarPanel"
                theme: root.theme
                visible: window.isTarget
                width: Math.max(0, Math.min(root.theme.sidebar.width, window.width - root.theme.sidebar.margin * 2))
                height: Math.max(0, window.height - y - root.theme.sidebar.margin)
                y: root.theme.topBar.windowHeight + root.theme.sidebar.gap
                x: lifecycle.shown ? window.width - width - root.theme.sidebar.margin : window.width
                color: root.theme.colors.topBarSurface
                border.width: root.theme.topBar.dividerWidth
                border.color: root.theme.colors.separator
                Behavior on x {
                    NumberAnimation { duration: root.theme.sidebar.animationDuration; easing.type: Easing.InOutCubic }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onClicked: event => event.accepted = true
                    onWheel: event => event.accepted = true
                }
                SidebarContent {
                    id: content
                    anchors.fill: parent
                    anchors.margins: root.theme.sidebar.padding
                    theme: root.theme
                    user: root.user
                    clock: root.clock
                    notifications: root.notifications
                    widgets: root.widgets
                }
                Connections {
                    target: controller
                    function onOpened() { content.resetCalendar(); }
                }
            }
        }
    }
}
