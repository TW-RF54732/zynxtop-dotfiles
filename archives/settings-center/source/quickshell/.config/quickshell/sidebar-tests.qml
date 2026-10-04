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
            content.resetCalendar();
            host.height = 280;
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
            root.check(upper.height <= content.height * 0.55 + 1 && upper.contentHeight > upper.height,
                "small-height header scrolls within its 55 percent budget");
            root.check(center.height > 50 && center.y + center.height <= content.height + 1,
                "small-height layout preserves a usable notification viewport");
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
            console.log(root.failures ? "FAIL: sidebar checks" : "PASS: sidebar checks");
            Qt.quit();
        }
    }
}
