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
    // CalendarService; edits happen in the calendar window, reached via the signals below.
    property var calendar: null
    property list<Component> widgets: []
    signal addEventRequested(string dateKey)
    signal editEventRequested(var event)
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
            // Position from the screen size, not window.width: the layer surface reports
            // 0 (or a stale size) while unmapped, which made x animate in from the left.
            readonly property real layoutWidth: modelData.width
            readonly property bool isTarget: screen === controller.targetScreen
            // Event shown in the flyout beside the panel; null when closed.
            property var selectedEvent: null
            property real flyoutY: 0
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
                onActivated: {
                    if (window.selectedEvent) window.selectedEvent = null;
                    else controller.hide();
                }
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
                width: Math.max(0, Math.min(root.theme.sidebar.width, window.layoutWidth - root.theme.sidebar.margin * 2))
                height: Math.max(0, window.height - y - root.theme.sidebar.margin)
                y: root.theme.topBar.windowHeight + root.theme.sidebar.gap
                x: lifecycle.shown ? window.layoutWidth - width - root.theme.sidebar.margin : window.layoutWidth
                color: root.theme.colors.topBarSurface
                border.width: root.theme.topBar.dividerWidth
                border.color: root.theme.colors.separator
                Behavior on x {
                    NumberAnimation { duration: root.theme.sidebar.animationDuration; easing.type: Easing.InOutCubic }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onClicked: event => { event.accepted = true; window.selectedEvent = null; }
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
                    calendarService: root.calendar
                    selectedEventKey: window.selectedEvent ? window.selectedEvent.key : ""
                    onDaySelected: window.selectedEvent = null
                    onAddRequested: dateKey => { controller.hide(); root.addEventRequested(dateKey); }
                    onEventActivated: event => {
                        if (window.selectedEvent && window.selectedEvent.key === event.key) {
                            window.selectedEvent = null;
                            return;
                        }
                        window.flyoutY = panel.y + content.agendaItem.mapToItem(panel, 0, 0).y;
                        window.selectedEvent = event;
                    }
                }
                Connections {
                    target: controller
                    function onOpened() { window.selectedEvent = null; content.resetCalendar(); }
                    function onRequestedVisibleChanged() { if (!controller.requestedVisible) window.selectedEvent = null; }
                }
            }
            EventFlyout {
                theme: root.theme
                event: window.isTarget ? window.selectedEvent : null
                x: panel.x - root.theme.sidebar.gap - width
                y: Math.min(window.flyoutY, window.height - height - root.theme.sidebar.margin)
                dayLabel: content.selectedKey.replace(/-/g, "/")
                onEditRequested: event => { controller.hide(); root.editEventRequested(event); }
                onDeleteRequested: event => {
                    window.selectedEvent = null;
                    if (root.calendar) root.calendar.remove(event.uid);
                }
            }
        }
    }
}
