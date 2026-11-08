pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../components"
import "../dashboard"
import "Calendar.js" as Calendar

ColumnLayout {
    id: root
    required property var theme
    required property var user
    required property var clock
    required property var notifications
    // CalendarService; null leaves the agenda empty (tests, previews).
    property var calendarService: null
    property list<Component> widgets: []
    // Key of the event shown in the flyout, owned by the host window.
    property string selectedEventKey: ""
    readonly property date today: clock.displayDate
    readonly property string todayKey: Calendar.dateKey(today.getFullYear(), today.getMonth(), today.getDate())
    property var selectedDay: ({year: today.getFullYear(), month: today.getMonth(), day: today.getDate()})
    readonly property string selectedKey: Calendar.cellKey(selectedDay)
    readonly property var selectedEvents: calendarService ? (calendarService.eventsByDay[selectedKey] || []) : []
    readonly property string agendaStatus: !calendarService || !calendarService.ready ? ""
        : calendarService.missing.length > 0 ? "UNAVAILABLE"
        : calendarService.syncing ? "SYNC…" : ""
    readonly property alias agendaItem: agenda
    signal eventActivated(var event)
    signal addRequested(string dateKey)
    signal daySelected()
    spacing: 16

    // The service caches the 42 visible cells; follows month paging.
    function requestVisibleRange() {
        if (!calendarService) return;
        const cells = monthView.cells;
        const last = cells[cells.length - 1];
        const after = new Date(Date.UTC(last.year, last.month, last.day + 1));
        calendarService.setRange(Calendar.cellKey(cells[0]),
            Calendar.dateKey(after.getUTCFullYear(), after.getUTCMonth(), after.getUTCDate()));
    }
    onCalendarServiceChanged: requestVisibleRange()
    Component.onCompleted: requestVisibleRange()

    function resetCalendar() {
        monthView.reset();
        selectDay({year: today.getFullYear(), month: today.getMonth(), day: today.getDate()});
    }
    function selectDay(cell) {
        selectedDay = {year: cell.year, month: cell.month, day: cell.day};
        if (cell.year !== monthView.displayedYear || cell.month !== monthView.displayedMonth) {
            monthView.displayedYear = cell.year;
            monthView.displayedMonth = cell.month;
        }
        daySelected();
        Qt.callLater(agenda.scrollToFocus);
    }

    Flickable {
        objectName: "sidebarUpperScroll"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(upper.implicitHeight, root.height * 0.45)
        Layout.minimumHeight: 0
        contentWidth: width
        contentHeight: upper.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: upper
            width: parent.width
            spacing: 16
            UserCard { theme: root.theme; user: root.user; today: root.clock.displayDate; Layout.fillWidth: true }
            Separator { theme: root.theme; Layout.fillWidth: true }
            CalendarPanel {
                id: monthView
                theme: root.theme
                today: root.clock.displayDate
                selectedKey: root.selectedKey
                markedDays: root.calendarService ? root.calendarService.markedDays : ({})
                Layout.fillWidth: true
                onDaySelected: cell => root.selectDay(cell)
                onCellsChanged: root.requestVisibleRange()
            }
            Repeater {
                model: root.widgets
                Loader {
                    required property Component modelData
                    Layout.fillWidth: true
                    sourceComponent: modelData
                }
            }
        }
    }
    Separator { theme: root.theme; Layout.fillWidth: true }
    AgendaPanel {
        id: agenda
        theme: root.theme
        selectedDay: root.selectedDay
        isToday: root.selectedKey === root.todayKey
        nowMinute: root.today.getHours() * 60 + root.today.getMinutes()
        events: root.selectedEvents
        selectedKey: root.selectedEventKey
        status: root.agendaStatus
        Layout.fillWidth: true
        // Fixed height; only gives way on very short screens.
        Layout.preferredHeight: Math.min(root.theme.sidebar.agendaHeight, root.height * 0.3)
        Layout.maximumHeight: Layout.preferredHeight
        onEventActivated: event => root.eventActivated(event)
        onAddRequested: root.addRequested(root.selectedKey)
    }
    Separator { theme: root.theme; Layout.fillWidth: true }
    NotificationCenter {
        objectName: "sidebarNotifications"
        theme: root.theme
        notifications: root.notifications
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 0
    }
}
