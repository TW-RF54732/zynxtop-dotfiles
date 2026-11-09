pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "app"
import "calendar"
import "sidebar/Calendar.js" as Calendar

// Calendar week window (app layer): glass sidebar with the month and calendar sources,
// solid week grid, and sentence-style cards for events and subscriptions.
FloatingWindow {
    id: root

    required property var theme
    required property var calendar
    // "YYYY-MM-DD" of today and minutes since midnight in the shell's display time zone.
    required property string todayKey
    property int nowMinute: 0
    property string weekStart: Calendar.weekStart(todayKey)
    // Event card: formOpen with editingUid "" is a new event (or a read-only one being viewed).
    property bool formOpen: false
    property string editingUid: ""
    property string formError: ""
    property bool saving: false
    property string selectedKey: ""
    // Where the card points, in grid coordinates; set before the card opens.
    property rect anchorRect: Qt.rect(0, 0, 0, 0)
    property var pendingAnchor: null
    property string pendingDate: ""
    property bool loadingEvent: false
    // Subscription card: "" closed, "add", or a subscription id.
    property string subscriptionCard: ""
    property real subscriptionY: 0
    readonly property var currentSubscription: calendar.subscriptions.find(item => item.id === subscriptionCard) || null
    readonly property var ghost: formOpen && editingUid === "" && !editor.readOnly
        ? {date: editor.date, startMin: editor.startMin, endMin: editor.endMin, allDay: editor.allDay, title: editor.title}
        : null

    title: "Calendar"
    visible: false
    implicitWidth: theme.calendarWindow.width
    implicitHeight: theme.calendarWindow.height
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: Qt.size(implicitWidth, implicitHeight)
    color: "transparent"

    function present() {
        const opening = !visible;
        if (opening) showWeek(Calendar.weekStart(todayKey));
        visible = true;
        minimized = false;
        calendar.setWeek(weekStart);
        if (opening) Qt.callLater(() => grid.scrollToStart());
    }
    function dismiss() {
        closeCards();
        visible = false;
    }
    function toggleVisibility() {
        if (visible) dismiss();
        else present();
    }
    function showWeek(start) {
        weekStart = start;
        calendar.setWeek(start);
    }
    function goToDate(key) {
        const start = Calendar.weekStart(key);
        if (start !== weekStart) showWeek(start);
    }
    function closeCards() {
        closeForm();
        subscriptionCard = "";
    }

    // ---- events ----
    function newEvent(dateKey, startMin, endMin, allDay) {
        present();
        subscriptionCard = "";
        const date = dateKey || todayKey;
        const start = startMin === undefined ? 9 * 60 : startMin;
        const end = endMin === undefined ? start + 60 : endMin;
        goToDate(date);
        selectedKey = "";
        fillForm({title: "", date: date, allDay: allDay === true, days: 1,
            startMin: start, endMin: end, location: "", description: "", repeat: ""});
        if (!allDay) grid.reveal(start, end);
        anchorRect = grid.rectFor(date, start, end, allDay === true);
        Qt.callLater(() => editor.focusTitle());
    }
    // From the Sidebar: `dateKey` is the occurrence to show (a series loads its first date).
    // From the Sidebar's week button: open on the week containing `dateKey`.
    function showDate(dateKey) {
        present();
        goToDate(dateKey || todayKey);
    }
    function openEvent(uid, dateKey) {
        present();
        subscriptionCard = "";
        pendingAnchor = null;
        pendingDate = dateKey || "";
        if (dateKey) goToDate(dateKey);
        formError = "";
        loadingEvent = true;
        calendar.load(uid, "window");
    }
    function activateEvent(event, rect) {
        subscriptionCard = "";
        selectedKey = event.key;
        if (event.readOnly) {
            fillForm(event);
            anchorRect = rect;
            return;
        }
        formOpen = false;
        pendingAnchor = rect;
        pendingDate = event.date;
        loadingEvent = true;
        calendar.load(event.uid, "window");
    }
    function fillForm(event) {
        editor.fill(event);
        editingUid = event.readOnly ? "" : (event.uid || "");
        formError = "";
        saving = false;
        formOpen = true;
    }
    function closeForm() {
        formOpen = false;
        editingUid = "";
        formError = "";
        saving = false;
        selectedKey = "";
        pendingAnchor = null;
        loadingEvent = false;
    }
    function submitForm() {
        if (editor.readOnly) return;
        const result = editor.collect();
        if (result.error) {
            formError = result.error;
            return;
        }
        formError = "";
        saving = true;
        if (editingUid) calendar.update(editingUid, result.event);
        else calendar.create(result.event);
    }

    // ---- subscriptions ----
    function openSubscription(id, row) {
        closeForm();
        subscriptionY = row.mapToItem(content, 0, 0).y - root.theme.calendarWindow.titleBarHeight;
        subscriptionCard = id;
        calendar.lastError = "";
        if (id === "add") subscriptionPanel.reset();
    }

    onClosed: dismiss()

    Connections {
        target: root.calendar
        function onEventLoaded(event, requester) {
            if (requester !== "window" || !root.loadingEvent || !root.visible) return;
            root.loadingEvent = false;
            root.fillForm(event);
            if (root.pendingAnchor) {
                root.anchorRect = root.pendingAnchor;
            } else {
                const date = root.pendingDate || event.date;
                root.goToDate(date);
                if (!event.allDay) grid.reveal(event.startMin, event.endMin);
                root.anchorRect = grid.rectFor(date, event.startMin, event.endMin, event.allDay === true);
            }
            root.pendingAnchor = null;
        }
        // The Sidebar flyout saves through the same service; only react to our own requests.
        function onSaved(op, uid) { if (root.saving) root.closeForm(); }
        function onFailed(op, message) {
            if (!root.saving && !(op === "get" && root.loadingEvent)) return;
            root.saving = false;
            root.loadingEvent = false;
            root.formError = message;
        }
        function onSubscribed(id) { root.subscriptionCard = id; }
    }

    IpcHandler {
        target: "calendar"
        function show(): void { root.present(); }
        function hide(): void { root.dismiss(); }
        function toggle(): void { root.toggleVisibility(); }
        function newEvent(date: string): void { root.newEvent(date); }
        function showDate(date: string): void { root.showDate(date); }
        function sync(): void { root.calendar.sync(); }
    }

    Item {
        id: content
        anchors.fill: parent

        // Glass: Hyprland blurs whatever shows through this translucent base.
        Rectangle { anchors.fill: parent; color: root.theme.app.glass }

        // ---- title bar ----
        AppTitleBar {
            id: titleBar
            width: parent.width
            theme: root.theme
            title: Calendar.weekTitle(root.weekStart)
            subtitle: "第 " + Calendar.isoWeek(root.weekStart) + " 週"
            onMoveRequested: root.startSystemMove()
            onDoubleClicked: root.showWeek(Calendar.weekStart(root.todayKey))

            AppButton {
                theme: root.theme
                text: "‹"
                onClicked: root.showWeek(Calendar.addDays(root.weekStart, -7))
            }
            AppButton {
                theme: root.theme
                text: "今天"
                onClicked: {
                    root.showWeek(Calendar.weekStart(root.todayKey));
                    grid.scrollToStart();
                }
            }
            AppButton {
                theme: root.theme
                text: "›"
                onClicked: root.showWeek(Calendar.addDays(root.weekStart, 7))
            }
            Item { width: 10; height: 1 }
            AppButton {
                objectName: "calendarAddButton"
                theme: root.theme
                primary: true
                text: "＋ 新增"
                interactive: root.calendar.available
                onClicked: {
                    const today = Calendar.weekStart(root.todayKey) === root.weekStart;
                    root.newEvent(today ? root.todayKey : root.weekStart);
                }
            }
        }

        // ---- glass sidebar: month navigator + calendar sources ----
        Column {
            id: sidebar
            x: 16
            y: titleBar.height + 4
            width: root.theme.calendarWindow.sidebarWidth - 32
            spacing: 22

            MiniMonth {
                id: month
                width: parent.width
                theme: root.theme
                todayKey: root.todayKey
                weekStart: root.weekStart
                onPicked: key => root.goToDate(key)
                Component.onCompleted: showDate(root.todayKey)
                Connections {
                    target: root
                    function onWeekStartChanged() {
                        const last = Calendar.addDays(root.weekStart, 6);
                        const shown = Calendar.dateKey(month.year, month.month, 1).slice(0, 7);
                        if (root.weekStart.slice(0, 7) !== shown && last.slice(0, 7) !== shown)
                            month.showDate(root.weekStart);
                    }
                }
            }
            SourceList {
                width: parent.width
                theme: root.theme
                calendars: root.calendar.calendars
                subscriptions: root.calendar.subscriptions
                syncing: root.calendar.syncing
                selectedId: root.subscriptionCard
                onSubscriptionActivated: (id, row) => root.openSubscription(id, row)
                onAddRequested: row => root.openSubscription("add", row)
                onSyncRequested: root.calendar.sync()
            }
        }

        // ---- solid content: the week ----
        ContentSurface {
            id: main
            theme: root.theme
            x: root.theme.calendarWindow.sidebarWidth
            y: titleBar.height
            width: parent.width - x
            height: parent.height - y

            UiText {
                anchors.centerIn: parent
                width: parent.width - 80
                visible: root.calendar.ready && !root.calendar.available
                theme: root.theme
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                lineHeight: 1.4
                text: "行事曆無法使用，缺少套件：" + root.calendar.missing.join(", ")
                    + "\n\nsudo pacman -S " + root.calendar.missing.join(" ")
            }

            WeekGrid {
                id: grid
                anchors.fill: parent
                anchors.topMargin: 4
                visible: root.calendar.available
                theme: root.theme
                weekStart: root.weekStart
                todayKey: root.todayKey
                nowMinute: root.nowMinute
                eventsByDay: root.calendar.weekStart === root.weekStart ? root.calendar.weekEvents : ({})
                selectedKey: root.selectedKey
                ghost: root.ghost
                onEventActivated: (event, rect) => root.activateEvent(event, rect)
                // With a card open, the first click on empty space only closes it.
                onSlotRequested: (date, startMin, endMin, allDay, rect) => {
                    if (root.formOpen || root.subscriptionCard) {
                        root.closeCards();
                        return;
                    }
                    root.newEvent(date, startMin, endMin, allDay);
                }
            }

            EventEditor {
                id: editor
                theme: root.theme
                todayKey: root.todayKey
                visible: root.formOpen
                editing: root.editingUid !== ""
                saving: root.saving
                error: root.formError
                z: 10
                // Beside the anchor (right if it fits, else left), kept inside the content.
                x: {
                    const right = grid.x + root.anchorRect.x + root.anchorRect.width + 8;
                    const left = grid.x + root.anchorRect.x - width - 8;
                    return right + width <= main.width - 8 ? right : Math.max(8, left);
                }
                y: Math.max(8, Math.min(grid.y + root.anchorRect.y, main.height - height - 8))
                onSaveRequested: root.submitForm()
                onCancelRequested: root.closeForm()
                onDeleteRequested: {
                    root.saving = true;
                    root.calendar.remove(root.editingUid);
                }
            }
        }

        SubscriptionCard {
            id: subscriptionPanel
            theme: root.theme
            visible: root.subscriptionCard !== ""
            adding: root.subscriptionCard === "add"
            subscription: root.currentSubscription
            syncing: root.calendar.syncing
            error: root.calendar.lastError
            x: root.theme.calendarWindow.sidebarWidth - 8
            y: Math.max(titleBar.height + 8, Math.min(titleBar.height + root.subscriptionY - 16,
                content.height - height - 8))
            z: 10
            onCancelRequested: root.subscriptionCard = ""
            onSubscribeRequested: (name, url) => root.calendar.subscribe(name, url)
            onSyncRequested: root.calendar.sync()
            onRemoveRequested: id => {
                root.calendar.unsubscribe(id);
                root.subscriptionCard = "";
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.formOpen && editor.dismissInner()) return;
            if (root.formOpen) root.closeForm();
            else if (root.subscriptionCard) root.subscriptionCard = "";
            else root.dismiss();
        }
    }
}
