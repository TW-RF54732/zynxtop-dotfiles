pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "../calendar"

// Event card split off the Sidebar's left side, styled like the Dashboard flyout. Views and
// edits an event in place with the calendar window's sentence form (shell skin); subscription
// events are read-only. The content stays on the last event while fading out.
GlassFrame {
    id: root
    objectName: "sidebarEventFlyout"

    // CalendarService; null disables saving (tests, previews).
    property var calendar: null
    required property string todayKey
    property bool open: false
    // Occurrence key of the event shown; "" for a new event.
    property string eventKey: ""
    property string editingUid: ""
    property bool saving: false
    property bool loading: false
    property string error: ""
    readonly property alias editor: editor
    // Pending new event, for the timeline's dashed preview.
    readonly property var ghost: open && eventKey === "" && !editor.readOnly
        ? {date: editor.date, startMin: editor.startMin, endMin: editor.endMin, allDay: editor.allDay, title: editor.title}
        : null
    property real reveal: open ? 1 : 0

    function reset() {
        eventKey = "";
        editingUid = "";
        saving = false;
        loading = false;
        error = "";
    }
    // `event` is an occurrence from the agenda. Local events are reloaded to get the series
    // fields (repeat, days); the occurrence is shown meanwhile.
    function showEvent(event) {
        reset();
        eventKey = event.key || "";
        editor.fill(event);
        if (!event.readOnly && calendar) {
            editingUid = event.uid;
            loading = true;
            calendar.load(event.uid, "sidebar");
        }
        open = true;
    }
    function newEvent(dateKey, startMin, endMin) {
        reset();
        editor.fill({title: "", date: dateKey, allDay: false, days: 1, startMin: startMin, endMin: endMin,
            location: "", description: "", repeat: "", calendar: "local", calendarName: "本機"});
        open = true;
        Qt.callLater(() => editor.focusTitle());
    }
    function close() {
        open = false;
        reset();
    }
    // Esc inside the card: leave time typing / the date picker first.
    function dismissInner() { return open && editor.dismissInner(); }
    function submit() {
        if (!calendar || editor.readOnly || loading || saving) return;
        const result = editor.collect();
        if (result.error) {
            error = result.error;
            return;
        }
        error = "";
        saving = true;
        if (editingUid) calendar.update(editingUid, result.event);
        else calendar.create(result.event);
    }
    // Deletes run directly, without confirmation.
    function remove() {
        if (!calendar || !editingUid || saving) return;
        saving = true;
        calendar.remove(editingUid);
    }

    Connections {
        target: root.calendar
        ignoreUnknownSignals: true
        function onEventLoaded(event, requester) {
            if (requester !== "sidebar" || !root.loading || event.uid !== root.editingUid) return;
            root.loading = false;
            root.editor.fill(event);
        }
        function onSaved(op, uid) { if (root.saving) root.close(); }
        function onFailed(op, message) {
            if (!root.saving && !root.loading) return;
            root.saving = false;
            root.loading = false;
            root.error = message;
        }
    }

    radius: theme.topBar.radius
    color: theme.colors.topBarSurface
    border.width: theme.topBar.dividerWidth
    border.color: theme.colors.separator
    antialiasing: true
    visible: reveal > 0
    opacity: reveal
    width: theme.sidebar.flyoutWidth
    height: editor.height

    Behavior on reveal { NumberAnimation { duration: root.theme.sidebar.flyoutDuration; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: root.open; NumberAnimation { duration: root.theme.sidebar.flyoutDuration; easing.type: Easing.OutCubic } }

    // Clicks inside the card must not reach the window's close-on-outside-click area.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: event => event.accepted = true
        onWheel: event => event.accepted = true
    }

    EventEditor {
        id: editor
        theme: root.theme.shellForms
        todayKey: root.todayKey
        width: root.width
        editing: root.editingUid !== ""
        saving: root.saving
        error: root.error
        onSaveRequested: root.submit()
        onCancelRequested: root.close()
        onDeleteRequested: root.remove()
    }
}
