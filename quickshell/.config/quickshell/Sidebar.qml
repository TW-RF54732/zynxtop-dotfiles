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
    // CalendarService; events are viewed and edited in place in the flyout.
    property var calendar: null
    property list<Component> widgets: []
    // The agenda's week button: open the calendar window on this day's week.
    signal weekRequested(string dateKey)
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
            property real flyoutY: 0
            // The flyout lines up with the top of the agenda.
            function placeFlyout() { flyoutY = panel.y + content.agendaItem.mapToItem(panel, 0, 0).y; }
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
                    if (flyout.dismissInner()) return;
                    if (flyout.open) flyout.close();
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
                    onClicked: event => { event.accepted = true; flyout.close(); }
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
                    selectedEventKey: flyout.open ? flyout.eventKey : ""
                    ghost: flyout.ghost
                    onDaySelected: flyout.close()
                    onAddRequested: dateKey => {
                        // Today: the next full hour; other days: 09:00.
                        const start = dateKey === content.todayKey
                            ? Math.min(23 * 60, Math.ceil((content.today.getHours() * 60 + content.today.getMinutes() + 1) / 60) * 60)
                            : 9 * 60;
                        window.placeFlyout();
                        flyout.newEvent(dateKey, start, start + 60);
                        content.agendaItem.revealRange(start, start + 60);
                    }
                    // With the card open, a click on empty time only closes it.
                    onSlotRequested: (dateKey, minute) => {
                        if (flyout.open) {
                            flyout.close();
                            return;
                        }
                        window.placeFlyout();
                        flyout.newEvent(dateKey, minute, minute + 60);
                    }
                    onEventActivated: event => {
                        if (flyout.open && flyout.eventKey === event.key) {
                            flyout.close();
                            return;
                        }
                        window.placeFlyout();
                        flyout.showEvent(event);
                    }
                    onWeekRequested: dateKey => {
                        controller.hide();
                        root.weekRequested(dateKey);
                    }
                }
                Connections {
                    target: controller
                    function onOpened() { flyout.close(); content.resetCalendar(); }
                    function onRequestedVisibleChanged() { if (!controller.requestedVisible) flyout.close(); }
                }
            }
            EventFlyout {
                id: flyout
                theme: root.theme
                calendar: root.calendar
                todayKey: content.todayKey
                x: panel.x - root.theme.sidebar.gap - width
                y: Math.max(panel.y, Math.min(window.flyoutY, window.height - height - root.theme.sidebar.margin))
            }
        }
    }
}
