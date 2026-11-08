import QtQuick
import Quickshell
import "services"
import "."

// CalendarService against the real backend (isolated XDG dirs from tests/run-calendar.sh).
ShellRoot {
    id: root
    property int failures: 0
    property string step: "start"
    function check(condition, message) {
        if (!condition) { failures++; console.error("FAIL: " + message); }
    }
    function finish() {
        console.log(failures ? "FAIL: calendar service checks" : "PASS: calendar service checks");
        Qt.quit();
    }
    CalendarService {
        id: calendar
        onAvailableChanged: if (available && root.step === "start") {
            root.step = "create";
            setRange("2026-11-01", "2026-11-15");
            setManagerStart("2026-11-08");
            // Through the manager window: a bad time range is rejected locally, then a valid save.
            manager.newEvent("2026-11-09");
            root.check(manager.visible && manager.formOpen && manager.editingUid === "", "new event opens an empty form");
            manager.fillForm({title: "測試事項", date: "2026-11-09", startMin: 660, endMin: 600});
            manager.submitForm();
            root.check(manager.formError !== "" && !manager.saving, "end before start is rejected in the form");
            manager.fillForm({title: "測試事項", date: "2026-11-09", startMin: 600, endMin: 660});
            manager.submitForm();
            root.check(manager.saving, "valid form is sent to the service");
        }
        onSaved: (op, uid) => {
            if (op === "create") root.step = "created:" + uid;
            else if (op === "delete") root.step = "deleted";
        }
        onFailed: (op, message) => { root.check(false, op + ": " + message); root.finish(); }
    }
    // Replies arrive in any order, so poll for each step's expected state.
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            const day = calendar.eventsByDay["2026-11-09"];
            if (root.step.startsWith("created:") && day && calendar.managerEvents.length === 1) {
                const event = day[0];
                root.check(event.title === "測試事項" && event.startMin === 600 && !event.readOnly,
                    "created event appears in the sidebar range");
                root.check(calendar.markedDays["2026-11-09"] === true && !calendar.markedDays["2026-11-08"],
                    "days with events are marked");
                root.check(calendar.managerEvents[0].uid === event.uid, "manager list shows the local event");
                root.check(!manager.formOpen, "saving closes the form");
                root.step = "deleting";
                calendar.remove(event.uid);
            } else if (root.step === "deleted" && !day && calendar.managerEvents.length === 0) {
                root.check(Object.keys(calendar.markedDays).length === 0, "deleting clears the marks");
                root.step = "done";
                root.finish();
            }
        }
    }
    Style { id: theme }
    CalendarWindow { id: manager; theme: theme; calendar: calendar; todayKey: "2026-11-08" }
    Timer { interval: 12000; running: true; onTriggered: { root.check(false, "timed out at " + root.step); root.finish(); } }
}
