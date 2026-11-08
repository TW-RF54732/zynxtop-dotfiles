import QtQuick
import QtQuick.Window
import Quickshell
import "services"
import "sidebar"
import "components"
import "sidebar/Calendar.js" as Calendar

ShellRoot {
    id: root
    property int failures: 0
    function check(condition, message) {
        if (!condition) { failures++; console.error("FAIL: " + message); }
    }
    function findItem(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = findItem(child, name);
            if (found) return found;
        }
        return null;
    }
    Style { id: theme }
    NotificationService { id: notifications }
    QtObject { id: user; property string displayName: "測試使用者"; property string avatar: "" }
    QtObject { id: clock; property date displayDate: new Date(2024, 1, 29, 23, 59) }
    // Stand-in for CalendarService: today (2024-03-01 after the midnight step) has two events.
    QtObject {
        id: calendarStub
        property bool ready: true
        property var missing: []
        property bool syncing: false
        property string rangeStart: ""
        property string rangeEnd: ""
        function setRange(start, end) { rangeStart = start; rangeEnd = end; }
        property var markedDays: ({"2024-03-01": true})
        property var eventsByDay: ({"2024-03-01": [
            {key: "p3", uid: "p3", title: "會議", allDay: false, startMin: 600, endMin: 690, readOnly: true},
            {key: "p6", uid: "p6", title: "截止", allDay: false, startMin: 1439, endMin: 1439, readOnly: true}
        ]})
    }
    // Stand-in for CalendarService's editing side, recording what the flyout sends.
    QtObject {
        id: editStub
        property var calls: []
        signal eventLoaded(var event, string requester)
        signal saved(string op, string uid)
        signal failed(string op, string message)
        function load(uid, requester) { calls = calls.concat(["load:" + uid + ":" + requester]); }
        function create(event) { calls = calls.concat(["create:" + event.title + ":" + event.startMin]); }
        function update(uid, event) { calls = calls.concat(["update:" + uid + ":" + event.startMin + "-" + event.endMin]); }
        function remove(uid) { calls = calls.concat(["delete:" + uid]); }
    }
    QtObject { id: firstScreen; property string name: "first" }
    QtObject { id: secondScreen; property string name: "second" }
    SidebarController {
        id: controller
        screens: [firstScreen, secondScreen]
        focusedMonitorName: "second"
    }
    AnimatedVisibility {
        id: lifecycle
        duration: theme.sidebar.animationDuration
        requestedVisible: controller.requestedVisible
    }
    Window {
        id: host
        width: 360; height: 760
        visible: true
        SidebarContent {
            id: content
            anchors.fill: parent
            theme: theme; user: user; clock: clock; notifications: notifications
            calendarService: calendarStub
            ghost: flyout.ghost
        }
        EventFlyout {
            id: flyout
            theme: theme
            calendar: editStub
            todayKey: "2024-03-01"
        }
        CalendarPanel {
            id: calendar
            width: 360
            theme: theme
            today: clock.displayDate
            visible: false
        }
    }
    Timer {
        interval: 100; running: true
        onTriggered: {
            const leap = Calendar.monthCells(2024, 1);
            root.check(leap.length === 42 && leap[0].day === 29 && leap[0].month === 0,
                "February starts on Monday of the preceding week");
            root.check(leap.filter(cell => cell.month === 1).length === 29, "leap February has 29 days");
            root.check(Calendar.monthCells(2025, 1).filter(cell => cell.month === 1).length === 28,
                "ordinary February has 28 days");
            root.check(Calendar.monthCells(2024, 0)[0].day === 1, "Monday month starts without an extra week");
            root.check(Calendar.monthCells(2023, 0)[0].day === 26, "Sunday month starts with six preceding days");
            root.check(leap.filter(cell => Calendar.sameDay(cell, clock.displayDate)).length === 1,
                "today is highlighted once");
            calendar.displayedYear = 2024; calendar.displayedMonth = 11;
            calendar.stepMonth(1);
            root.check(calendar.displayedYear === 2025 && calendar.displayedMonth === 0, "next month crosses year");
            calendar.stepMonth(-1);
            root.check(calendar.displayedYear === 2024 && calendar.displayedMonth === 11, "previous month crosses year");
            calendar.reset();
            root.check(calendar.displayedMonth === 1, "today button returns to February");
            clock.displayDate = new Date(2024, 2, 1, 0, 0);
            root.check(Calendar.sameDay({year: 2024, month: 2, day: 1}, calendar.today),
                "midnight updates today from the shared wall clock");
            const ev = (key, start, end, allDay) => ({key: key, title: key, startMin: start, endMin: end, allDay: !!allDay});
            const laid = Calendar.layoutDay([ev("a", 600, 660), ev("b", 630, 720), ev("c", 660, 690),
                ev("d", 800, 830), ev("all", 0, 1440, true), ev("z", 1439, 1439)]);
            const byKey = {}; laid.forEach(item => byKey[item.event.key] = item);
            root.check(laid.length === 5 && !byKey.all, "all-day events stay out of the timeline columns");
            root.check(byKey.a.columns === 2 && byKey.b.columns === 2 && byKey.c.columns === 2,
                "chained overlaps share one column count");
            root.check(byKey.a.column === 0 && byKey.b.column === 1 && byKey.c.column === 0,
                "a freed column is reused");
            root.check(byKey.d.columns === 1 && byKey.d.column === 0, "separate cluster resets columns");
            root.check(byKey.z.end === 1440 && byKey.z.start === 1439, "zero-length event near midnight stays inside the day");
            root.check(Calendar.dateKey(2024, 1, 9) === "2024-02-09", "date keys are zero padded");
            root.check(Calendar.timeLabel(ev("t", 545, 1440)) === "09:05 – 24:00", "time label formats minutes");

            content.resetCalendar();

            // Flyout: subscription events are read-only and not reloaded.
            flyout.showEvent({key: "p3", uid: "p3", title: "會議", date: "2024-03-01", allDay: false,
                startMin: 600, endMin: 690, readOnly: true, calendar: "sub-12345678", calendarName: "課表"});
            root.check(flyout.open && flyout.editor.readOnly && flyout.ghost === null && editStub.calls.length === 0,
                "subscription events open read-only without a reload");
            // Local events reload the series; only replies tagged for the sidebar are taken.
            flyout.showEvent({key: "local/a/2024-03-01", uid: "a", title: "讀書", date: "2024-03-01", allDay: false,
                startMin: 600, endMin: 660, readOnly: false, recurring: true, calendar: "local"});
            root.check(editStub.calls[0] === "load:a:sidebar" && flyout.loading && !flyout.editor.readOnly,
                "local events are loaded for editing");
            editStub.eventLoaded({uid: "a", title: "別的", date: "2024-02-02", startMin: 600, endMin: 660, repeat: "DAILY"}, "window");
            root.check(flyout.editor.title === "讀書" && flyout.loading, "replies for the window are ignored");
            editStub.eventLoaded({uid: "a", title: "讀書", date: "2024-02-02", startMin: 600, endMin: 660, repeat: "WEEKLY"}, "sidebar");
            root.check(!flyout.loading && flyout.editor.repeat === "WEEKLY", "the series fills the form");
            flyout.editor.setStart(630);
            root.check(flyout.editor.endMin === 690, "moving the start keeps the duration");
            flyout.submit();
            root.check(editStub.calls[1] === "update:a:630-690" && flyout.saving, "saving updates the event");
            editStub.saved("update", "a");
            root.check(!flyout.open, "a finished save closes the card");
            // New events: dashed preview on the timeline, title required.
            flyout.newEvent("2024-03-01", 840, 900);
            root.check(flyout.ghost && root.findItem(content, "agendaTimelineGhost").visible,
                "a new event is previewed on the timeline");
            flyout.submit();
            root.check(flyout.error !== "" && editStub.calls.length === 2, "an empty title is rejected locally");
            flyout.editor.title = "散步";
            flyout.submit();
            root.check(editStub.calls[2] === "create:散步:840", "a titled new event is created");
            editStub.failed("create", "disk full");
            root.check(flyout.open && !flyout.saving && flyout.error === "disk full", "backend errors stay in the card");
            flyout.editor.pickingDate = true;
            root.check(flyout.dismissInner() && !flyout.editor.pickingDate && flyout.open,
                "Esc closes the date picker before the card");
            flyout.close();
            root.check(!flyout.open && flyout.ghost === null, "closing clears the preview");

            root.check(calendarStub.rangeStart === "2024-02-26" && calendarStub.rangeEnd === "2024-04-08",
                "the visible 42-day grid is requested from the service");
            root.check(content.selectedEvents.length === 2, "today's events come from the service");
            const agenda = root.findItem(content, "sidebarAgenda");
            const pointer = root.findItem(content, "agendaNowPointer");
            root.check(content.selectedKey === "2024-03-01" && agenda.isToday && pointer.visible,
                "reset selects today and shows the now pointer");
            let activated = null;
            content.eventActivated.connect(event => activated = event);
            agenda.eventActivated({key: "x"});
            root.check(activated && activated.key === "x", "agenda events bubble up to the host");
            content.selectDay({year: 2024, month: 3, day: 2});
            root.check(content.selectedKey === "2024-04-02" && !agenda.isToday && !pointer.visible,
                "selecting another day moves the calendar and hides the pointer");
            root.check(root.findItem(content, "sidebarCalendar").displayedMonth === 3,
                "selecting an adjacent-month day follows to that month");
            content.resetCalendar();
            host.height = 520;
            smallLayout.restart();
            controller.show();
            root.check(controller.targetScreen === secondScreen && controller.requestedVisible,
                "opens on the focused monitor");
            controller.focusedMonitorName = "first";
            root.check(controller.targetScreen === secondScreen, "open panel stays on its original monitor");
            controller.hide(); controller.show(); controller.hide(); controller.show();
            reopened.restart();
        }
    }
    Timer {
        id: smallLayout; interval: 80
        onTriggered: {
            const upper = root.findItem(content, "sidebarUpperScroll");
            const center = root.findItem(content, "sidebarNotifications");
            const agenda = root.findItem(content, "sidebarAgenda");
            root.check(upper.height <= content.height * 0.45 + 1 && upper.contentHeight > upper.height,
                "small-height header scrolls within its 45 percent budget");
            root.check(agenda.height > 100 && agenda.height <= theme.sidebar.agendaHeight,
                "agenda keeps a fixed, bounded height");
            const timeline = root.findItem(content, "agendaTimeline");
            timeline.scrollToEvent({key: "p3", allDay: false});
            centered.restart();
            root.check(center.height > 50 && center.y + center.height <= content.height + 1,
                "small-height layout preserves a usable notification viewport");
        }
    }
    Timer {
        id: centered; interval: 700
        onTriggered: {
            const timeline = root.findItem(content, "agendaTimeline");
            const flick = root.findItem(content, "agendaTimelineScroll");
            const middle = timeline.minuteY(10 * 60 + 45) + 4;
            root.check(Math.abs(flick.contentY + flick.height / 2 - middle) < 1,
                "activating a list event centers it on the timeline");
            timeline.scrollToEvent({key: "p6", allDay: false});
            clamped.restart();
        }
    }
    Timer {
        id: clamped; interval: 700
        onTriggered: {
            const flick = root.findItem(content, "agendaTimelineScroll");
            root.check(Math.abs(flick.contentY - (flick.contentHeight - flick.height)) < 1,
                "a late event stops at the bottom bound instead of centering");
            // Last timer in the chain: the panel lifecycle checks finish well before.
            console.log(root.failures ? "FAIL: sidebar checks" : "PASS: sidebar checks");
            Qt.quit();
        }
    }
    Timer {
        id: reopened; interval: 300
        onTriggered: {
            root.check(lifecycle.mounted && lifecycle.shown && controller.targetScreen === firstScreen,
                "rapid reversal leaves the latest requested panel visible");
            controller.screens = [secondScreen];
            root.check(!controller.requestedVisible, "unplugging the target monitor closes the panel");
            closed.restart();
        }
    }
    Timer {
        id: closed; interval: 300
        onTriggered: {
            root.check(!lifecycle.mounted && !lifecycle.shown, "close animation releases mounted windows");
            controller.focusedMonitorName = "missing";
            controller.show();
            root.check(controller.targetScreen === secondScreen, "missing focus falls back to first screen");
            controller.hide(); controller.screens = []; controller.show();
            root.check(!controller.requestedVisible, "no screens means no panel");
        }
    }
}
