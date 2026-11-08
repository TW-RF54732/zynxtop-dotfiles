import QtQuick
import Quickshell

// Calendar state for the Sidebar agenda and the calendar week window.
// Storage, recurrence and subscriptions live in calendar_backend.py (vdir + vdirsyncer).
JsonProcessService {
    id: root

    property string timeZone: "Asia/Taipei"
    property int syncInterval: 30 * 60 * 1000
    readonly property bool available: ready && missing.length === 0
    property bool ready: false
    property var missing: []
    property bool syncing: false
    property var subscriptions: []
    property string lastError: ""

    // Sidebar range: [rangeStart, rangeEnd) as "YYYY-MM-DD"; events grouped per day.
    property string rangeStart: ""
    property string rangeEnd: ""
    property var eventsByDay: ({})
    property var markedDays: ({})
    // Week window: all calendars for [weekStart, weekStart + 7 days), grouped per day.
    property string weekStart: ""
    property var weekEvents: ({})
    // Calendar sources: [{id, name, readOnly}], local first.
    property var calendars: []

    signal saved(string op, string uid)
    signal failed(string op, string message)
    signal eventLoaded(var event)
    signal subscribed(string id)

    command: ["python3", "-I", Qt.resolvedUrl("calendar_backend.py").toString().replace("file://", ""),
        "--state", Quickshell.stateDir + "/calendar", "--tz", timeZone]

    function setRange(start, end) {
        if (start === rangeStart && end === rangeEnd) return;
        rangeStart = start;
        rangeEnd = end;
        requestRange();
    }
    function requestRange() {
        if (available && rangeStart && rangeEnd)
            send({op: "range", start: rangeStart, end: rangeEnd, tag: "sidebar"});
    }
    function setWeek(start) {
        if (start === weekStart) return;
        weekStart = start;
        weekEvents = {};
        requestWeek();
    }
    function requestWeek() {
        if (!available || !weekStart) return;
        const end = new Date(weekStart + "T00:00:00Z");
        end.setUTCDate(end.getUTCDate() + 7);
        send({op: "range", start: weekStart, end: end.toISOString().slice(0, 10), tag: "week"});
    }
    function requestCalendars() {
        if (available) send({op: "calendars"});
    }
    function refresh() {
        requestRange();
        requestWeek();
        requestCalendars();
    }

    function create(event) { lastError = ""; send({op: "create", event: event}); }
    function update(uid, event) { lastError = ""; send({op: "update", uid: uid, event: event}); }
    function remove(uid) { lastError = ""; send({op: "delete", uid: uid}); }
    function load(uid) { send({op: "get", uid: uid}); }
    function subscribe(name, url) { lastError = ""; send({op: "subscribe", name: name, url: url}); }
    function unsubscribe(id) { lastError = ""; send({op: "unsubscribe", subscriptionId: id}); }
    function sync() { if (available) send({op: "sync"}); }

    function groupByDay(events) {
        const days = {};
        for (const event of events) {
            if (!days[event.date]) days[event.date] = [];
            days[event.date].push(event);
        }
        return days;
    }
    function markDays(days) {
        const marks = {};
        for (const key in days) marks[key] = true;
        return marks;
    }
    onMessageReceived: message => {
        switch (message.op) {
        case "ready":
            ready = true;
            missing = [];
            refresh();
            break;
        case "unavailable":
            ready = true;
            missing = message.missing || [];
            break;
        case "subscriptions":
            subscriptions = message.items || [];
            requestCalendars();
            break;
        case "calendars":
            calendars = (message.items || []).slice().sort((a, b) =>
                a.id === "local" ? -1 : b.id === "local" ? 1 : String(a.name).localeCompare(String(b.name)));
            break;
        case "syncing":
            syncing = message.value === true;
            break;
        case "changed":
            refresh();
            break;
        case "range":
            if (message.tag === "sidebar" && message.start === rangeStart && message.end === rangeEnd) {
                const days = groupByDay(message.events || []);
                markedDays = markDays(days);
                eventsByDay = days;
            } else if (message.tag === "week" && message.start === weekStart) {
                weekEvents = groupByDay(message.events || []);
            }
            if (message.errors && message.errors.length) console.warn("calendar:", message.errors.join("; "));
            break;
        case "subscribe":
            subscribed(message.subscriptionId || "");
            break;
        case "get":
            eventLoaded(message.event);
            break;
        case "create": case "update": case "delete":
            saved(message.op, message.uid || "");
            break;
        case "error":
            lastError = message.message || "error";
            failed(message.request || "", lastError);
            break;
        }
    }
    onDisconnected: {
        ready = false;
        syncing = false;
    }
    // Pull subscriptions once at startup; the timer keeps them fresh afterwards.
    onAvailableChanged: if (available) sync()

    Timer {
        interval: root.syncInterval
        running: root.available
        repeat: true
        onTriggered: root.sync()
    }
}
