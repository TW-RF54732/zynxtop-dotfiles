pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "components"
import "sidebar/Calendar.js" as Calendar

// Calendar manager: local event CRUD and ICS subscriptions. Layout follows WireGuardWindow.
FloatingWindow {
    id: root

    required property var theme
    required property var calendar
    // "YYYY-MM-DD" of today in the shell's display time zone.
    required property string todayKey
    property string tab: "events"
    // Event editor state: formOpen with editingUid "" means a new event.
    property bool formOpen: false
    property string editingUid: ""
    property bool formAllDay: false
    property int formDays: 1
    property string formRepeat: ""
    property string formError: ""
    property bool saving: false
    // Subscriptions: selected id, or addingSubscription for the add form.
    property string selectedSubscription: ""
    property bool addingSubscription: false
    readonly property var currentSubscription: calendar.subscriptions.find(item => item.id === selectedSubscription) || null
    readonly property var repeatOptions: [
        {value: "", label: "不重複"}, {value: "DAILY", label: "每日"}, {value: "WEEKLY", label: "每週"},
        {value: "MONTHLY", label: "每月"}, {value: "YEARLY", label: "每年"}
    ]

    title: "Calendar"
    visible: false
    implicitWidth: theme.calendarWindow.width
    implicitHeight: theme.calendarWindow.height
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: Qt.size(implicitWidth, implicitHeight)
    color: "transparent"

    function present() {
        visible = true;
        minimized = false;
        calendar.setManagerStart(todayKey);
    }
    function dismiss() {
        closeForm();
        addingSubscription = false;
        visible = false;
    }
    function toggleVisibility() {
        if (visible) dismiss();
        else present();
    }
    function newEvent(dateKey) {
        present();
        tab = "events";
        editingUid = "";
        fillForm({title: "", date: dateKey || todayKey, allDay: false, days: 1,
            startMin: 9 * 60, endMin: 10 * 60, location: "", description: "", repeat: ""});
        Qt.callLater(() => titleField.forceActiveFocus());
    }
    function openEvent(uid) {
        present();
        tab = "events";
        formError = "";
        calendar.load(uid);
    }
    function fillForm(event) {
        editingUid = event.uid || "";
        titleField.text = event.title || "";
        dateField.text = event.date || todayKey;
        formAllDay = event.allDay === true;
        formDays = event.days || 1;
        startField.text = Calendar.formatMinutes(event.startMin === undefined ? 540 : event.startMin);
        endField.text = Calendar.formatMinutes(event.endMin === undefined ? 600 : event.endMin);
        locationField.text = event.location || "";
        notesField.text = event.description || "";
        formRepeat = event.repeat || "";
        formError = "";
        saving = false;
        formOpen = true;
    }
    function closeForm() {
        formOpen = false;
        editingUid = "";
        formError = "";
        saving = false;
    }
    function parseTime(text) {
        const match = /^(\d{1,2}):(\d{2})$/.exec(text.trim());
        if (!match) return -1;
        const minutes = Number(match[1]) * 60 + Number(match[2]);
        return Number(match[2]) < 60 && minutes <= 24 * 60 ? minutes : -1;
    }
    function submitForm() {
        const date = dateField.text.trim();
        if (!titleField.text.trim()) { formError = "請輸入標題"; return; }
        if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || isNaN(new Date(date + "T00:00:00Z"))) {
            formError = "日期格式為 YYYY-MM-DD"; return;
        }
        const start = parseTime(startField.text);
        const end = parseTime(endField.text);
        if (!formAllDay && (start < 0 || end < 0 || start >= 24 * 60)) { formError = "時間格式為 HH:MM"; return; }
        if (!formAllDay && end <= start) { formError = "結束時間需晚於開始時間"; return; }
        const event = {
            title: titleField.text.trim(), date: date, allDay: formAllDay, days: formDays,
            startMin: start, endMin: end, location: locationField.text.trim(),
            description: notesField.text, repeat: formRepeat
        };
        formError = "";
        saving = true;
        if (editingUid) calendar.update(editingUid, event);
        else calendar.create(event);
    }
    function maskUrl(url) {
        const match = /^(https?:\/\/[^\/]+)/i.exec(url || "");
        return match ? match[1] + "/…" : "";
    }
    function occurrenceLabel(event) {
        const day = event.date.slice(5).replace("-", "/");
        return day + "  " + (event.allDay ? "全天" : Calendar.formatMinutes(event.startMin));
    }

    onClosed: dismiss()

    Connections {
        target: root.calendar
        function onEventLoaded(event) { root.fillForm(event); }
        function onSaved(op, uid) { if (root.visible) root.closeForm(); }
        function onFailed(op, message) {
            if (["create", "update", "delete", "get"].includes(op)) {
                root.saving = false;
                root.formError = message;
            }
        }
        function onSubscribed(id) {
            root.addingSubscription = false;
            root.selectedSubscription = id;
        }
    }

    IpcHandler {
        target: "calendar"
        function show(): void { root.present(); }
        function hide(): void { root.dismiss(); }
        function toggle(): void { root.toggleVisibility(); }
        function newEvent(date: string): void { root.newEvent(date); }
        function sync(): void { root.calendar.sync(); }
    }

    component Label: MonoText {
        tone: theme.colors.textMuted
        font.pixelSize: 11
    }
    component Field: TextField {
        required property var theme
        Layout.fillWidth: true
        implicitHeight: 36
        color: theme.colors.textPrimary
        selectionColor: theme.colors.textSelection
        selectedTextColor: theme.colors.textPrimary
        font.family: theme.typography.family
        font.pixelSize: 13
        placeholderTextColor: theme.colors.textMuted
        leftPadding: 10
        rightPadding: 10
        background: Rectangle {
            color: parent.theme.colors.frame
            radius: parent.theme.geometry.cornerRadius
            border.width: parent.activeFocus ? 1 : 0
            border.color: parent.theme.colors.textMuted
        }
    }
    component SideRow: InteractiveSurface {
        id: sideRow
        property string primary: ""
        property string secondary: ""
        height: 48
        hoverEnabled: true
        Column {
            anchors.verticalCenter: parent.verticalCenter
            x: 14
            width: parent.width - 26
            spacing: 2
            MonoText {
                theme: sideRow.theme
                width: parent.width
                text: sideRow.primary
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: 13
                tone: sideRow.active ? sideRow.theme.colors.textPrimary : sideRow.theme.colors.textSecondary
            }
            MonoText {
                theme: sideRow.theme
                width: parent.width
                visible: text !== ""
                text: sideRow.secondary
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: 11
                tone: sideRow.theme.colors.textMuted
            }
        }
    }

    GlassFrame {
        anchors.fill: parent
        theme: root.theme

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.theme.geometry.frameWidth
            spacing: 0

            // Header: title (drag handle), tabs, close.
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 12
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                spacing: 4

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    MonoText {
                        anchors.verticalCenter: parent.verticalCenter
                        theme: root.theme
                        text: "CALENDAR"
                        font.pixelSize: 15
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        onPressed: root.startSystemMove()
                    }
                }
                TextButton {
                    objectName: "calendarEventsTab"
                    theme: root.theme
                    text: "EVENTS"
                    implicitHeight: 30
                    active: root.tab === "events"
                    onClicked: root.tab = "events"
                }
                TextButton {
                    objectName: "calendarSubscriptionsTab"
                    theme: root.theme
                    text: "SUBSCRIPTIONS"
                    implicitHeight: 30
                    active: root.tab === "subscriptions"
                    onClicked: root.tab = "subscriptions"
                }
                Item { implicitWidth: 12 }
                TextButton {
                    theme: root.theme
                    text: "CLOSE"
                    implicitHeight: 30
                    onClicked: root.dismiss()
                }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.theme.colors.separator }

            MonoText {
                Layout.fillWidth: true
                Layout.margins: 24
                visible: root.calendar.ready && !root.calendar.available
                theme: root.theme
                wrapMode: Text.Wrap
                font.pixelSize: 12
                tone: root.theme.colors.textSecondary
                text: "CALENDAR UNAVAILABLE\n\n缺少套件：" + root.calendar.missing.join(", ")
                    + "\n\nsudo pacman -S " + root.calendar.missing.join(" ")
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.calendar.available
                spacing: 0

                // Left column: upcoming local events or subscriptions.
                ColumnLayout {
                    Layout.preferredWidth: root.theme.calendarWindow.sidebarWidth
                    Layout.maximumWidth: root.theme.calendarWindow.sidebarWidth
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    spacing: 0

                    Label {
                        theme: root.theme
                        Layout.leftMargin: 16
                        Layout.topMargin: 16
                        Layout.bottomMargin: 8
                        text: root.tab === "events" ? "UPCOMING · 本機" : "ICS FEEDS"
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        ListView {
                            id: eventList
                            anchors.fill: parent
                            visible: root.tab === "events"
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.calendar.managerEvents
                            delegate: SideRow {
                                required property var modelData
                                theme: root.theme
                                width: eventList.width
                                primary: modelData.title
                                secondary: root.occurrenceLabel(modelData) + (modelData.recurring ? " · 重複" : "")
                                active: root.formOpen && root.editingUid === modelData.uid
                                onClicked: root.openEvent(modelData.uid)
                            }
                        }
                        ListView {
                            id: subscriptionList
                            anchors.fill: parent
                            visible: root.tab === "subscriptions"
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.calendar.subscriptions
                            delegate: SideRow {
                                required property var modelData
                                theme: root.theme
                                width: subscriptionList.width
                                primary: modelData.name
                                secondary: modelData.error ? "ERROR" : (modelData.lastSync || "尚未同步")
                                active: !root.addingSubscription && root.selectedSubscription === modelData.id
                                onClicked: {
                                    root.addingSubscription = false;
                                    root.selectedSubscription = modelData.id;
                                }
                            }
                        }
                        Label {
                            theme: root.theme
                            anchors.centerIn: parent
                            visible: root.tab === "events" ? eventList.count === 0 : subscriptionList.count === 0
                            text: "EMPTY"
                        }
                    }
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.theme.colors.separator }
                    TextButton {
                        objectName: "calendarAddButton"
                        theme: root.theme
                        Layout.fillWidth: true
                        Layout.margins: 10
                        implicitHeight: 38
                        text: root.tab === "events" ? "+  NEW EVENT" : "+  ADD FEED"
                        active: root.tab === "events" ? root.formOpen && root.editingUid === "" : root.addingSubscription
                        onClicked: {
                            if (root.tab === "events") root.newEvent(root.todayKey);
                            else {
                                subscriptionName.text = "";
                                urlField.text = "";
                                root.calendar.lastError = "";
                                root.addingSubscription = true;
                                Qt.callLater(() => subscriptionName.forceActiveFocus());
                            }
                        }
                    }
                }
                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }

                // Right column: editor / details.
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // ---- Events: empty state ----
                    Label {
                        theme: root.theme
                        anchors.centerIn: parent
                        visible: root.tab === "events" && !root.formOpen
                        text: "選擇事項或新增"
                    }

                    // ---- Events: editor ----
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        visible: root.tab === "events" && root.formOpen
                        spacing: 10

                        MonoText {
                            theme: root.theme
                            text: root.editingUid ? "EDIT EVENT" : "NEW EVENT"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Label { theme: root.theme; text: "TITLE" }
                        Field { id: titleField; theme: root.theme; placeholderText: "標題" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            ColumnLayout {
                                spacing: 6
                                Label { theme: root.theme; text: "DATE" }
                                Field { id: dateField; theme: root.theme; Layout.preferredWidth: 130; placeholderText: "YYYY-MM-DD" }
                            }
                            ColumnLayout {
                                spacing: 6
                                visible: !root.formAllDay
                                Label { theme: root.theme; text: "START" }
                                Field { id: startField; theme: root.theme; Layout.preferredWidth: 80; placeholderText: "09:00" }
                            }
                            ColumnLayout {
                                spacing: 6
                                visible: !root.formAllDay
                                Label { theme: root.theme; text: "END" }
                                Field { id: endField; theme: root.theme; Layout.preferredWidth: 80; placeholderText: "10:00" }
                            }
                            ColumnLayout {
                                spacing: 6
                                Label { theme: root.theme; text: " " }
                                TextButton {
                                    objectName: "calendarAllDayToggle"
                                    theme: root.theme
                                    text: "全天"
                                    implicitHeight: 36
                                    active: root.formAllDay
                                    onClicked: root.formAllDay = !root.formAllDay
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                        Label { theme: root.theme; text: "REPEAT" + (root.editingUid && root.formRepeat ? " · 修改會套用到整個系列" : "") }
                        Row {
                            spacing: 4
                            Repeater {
                                model: root.repeatOptions
                                TextButton {
                                    required property var modelData
                                    theme: root.theme
                                    text: modelData.label
                                    implicitHeight: 30
                                    active: root.formRepeat === modelData.value
                                    onClicked: root.formRepeat = modelData.value
                                }
                            }
                        }
                        Label { theme: root.theme; text: "LOCATION" }
                        Field { id: locationField; theme: root.theme; placeholderText: "地點（選填）" }
                        Label { theme: root.theme; text: "NOTES" }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 50
                            clip: true
                            TextArea {
                                id: notesField
                                color: root.theme.colors.textPrimary
                                selectionColor: root.theme.colors.textSelection
                                selectedTextColor: root.theme.colors.textPrimary
                                font.family: root.theme.typography.family
                                font.pixelSize: 12
                                wrapMode: TextEdit.Wrap
                                placeholderText: "備註（選填）"
                                placeholderTextColor: root.theme.colors.textMuted
                                padding: 10
                                background: Rectangle {
                                    color: root.theme.colors.frame
                                    radius: root.theme.geometry.cornerRadius
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            MonoText {
                                theme: root.theme
                                Layout.fillWidth: true
                                text: root.formError
                                tone: root.theme.colors.textSecondary
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                            }
                            TextButton {
                                objectName: "calendarDeleteButton"
                                theme: root.theme
                                visible: root.editingUid !== ""
                                text: "DELETE"
                                implicitHeight: 38
                                interactive: !root.saving
                                onClicked: { root.saving = true; root.calendar.remove(root.editingUid); }
                            }
                            TextButton {
                                theme: root.theme
                                text: "CANCEL"
                                implicitHeight: 38
                                onClicked: root.closeForm()
                            }
                            TextButton {
                                objectName: "calendarSaveButton"
                                theme: root.theme
                                text: root.saving ? "SAVING…" : "SAVE"
                                implicitWidth: 100
                                implicitHeight: 38
                                active: true
                                interactive: !root.saving
                                onClicked: root.submitForm()
                            }
                        }
                    }

                    // ---- Subscriptions: empty state ----
                    Label {
                        theme: root.theme
                        anchors.centerIn: parent
                        visible: root.tab === "subscriptions" && !root.addingSubscription && !root.currentSubscription
                        text: "選擇訂閱或新增 ICS 網址"
                    }

                    // ---- Subscriptions: add form ----
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        visible: root.tab === "subscriptions" && root.addingSubscription
                        spacing: 10
                        MonoText {
                            theme: root.theme
                            text: "ADD ICS FEED"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Label { theme: root.theme; text: "NAME" }
                        Field { id: subscriptionName; theme: root.theme; placeholderText: "Google、課表、假日…" }
                        Label { theme: root.theme; text: "URL" }
                        Field { id: urlField; theme: root.theme; placeholderText: "https://… 或 webcal://…  (.ics)" }
                        MonoText {
                            theme: root.theme
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.pixelSize: 11
                            tone: root.theme.colors.textMuted
                            text: "唯讀訂閱，由 vdirsyncer 每 30 分鐘同步。Google 日曆請用「設定 → 整合日曆 → iCal 格式的私密網址」。網址只存在本機狀態目錄（權限 600）。"
                        }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            Layout.fillWidth: true
                            MonoText {
                                theme: root.theme
                                Layout.fillWidth: true
                                text: root.calendar.lastError
                                tone: root.theme.colors.textSecondary
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                            }
                            TextButton {
                                theme: root.theme
                                text: "CANCEL"
                                implicitHeight: 38
                                onClicked: root.addingSubscription = false
                            }
                            TextButton {
                                theme: root.theme
                                text: "SUBSCRIBE"
                                implicitHeight: 38
                                active: true
                                interactive: subscriptionName.text.trim() !== "" && urlField.text.trim() !== ""
                                onClicked: root.calendar.subscribe(subscriptionName.text, urlField.text)
                            }
                        }
                    }

                    // ---- Subscriptions: details ----
                    ColumnLayout {
                        id: feedDetails
                        anchors.fill: parent
                        anchors.margins: 24
                        visible: root.tab === "subscriptions" && !root.addingSubscription && root.currentSubscription !== null
                        spacing: 14
                        readonly property var item: root.currentSubscription || ({})
                        MonoText {
                            theme: root.theme
                            Layout.fillWidth: true
                            text: feedDetails.item.name || ""
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.theme.colors.separator }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 8
                            Label { theme: root.theme; text: "URL"; font.pixelSize: 12 }
                            MonoText { theme: root.theme; text: root.maskUrl(feedDetails.item.url); font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                            Label { theme: root.theme; text: "LAST SYNC"; font.pixelSize: 12 }
                            MonoText { theme: root.theme; text: feedDetails.item.lastSync || "—"; font.pixelSize: 12 }
                            Label { theme: root.theme; text: "STATUS"; font.pixelSize: 12 }
                            MonoText {
                                theme: root.theme
                                Layout.fillWidth: true
                                text: root.calendar.syncing ? "SYNCING…" : (feedDetails.item.error || "OK")
                                wrapMode: Text.Wrap
                                font.pixelSize: 12
                                tone: feedDetails.item.error ? root.theme.colors.textSecondary : root.theme.colors.textPrimary
                            }
                        }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            Layout.fillWidth: true
                            Item { Layout.fillWidth: true }
                            TextButton {
                                theme: root.theme
                                text: "REMOVE"
                                implicitHeight: 38
                                onClicked: {
                                    root.calendar.unsubscribe(root.selectedSubscription);
                                    root.selectedSubscription = "";
                                }
                            }
                            TextButton {
                                theme: root.theme
                                text: root.calendar.syncing ? "SYNCING…" : "SYNC NOW"
                                implicitWidth: 120
                                implicitHeight: 38
                                active: true
                                interactive: !root.calendar.syncing
                                onClicked: root.calendar.sync()
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.formOpen) root.closeForm();
            else if (root.addingSubscription) root.addingSubscription = false;
            else root.dismiss();
        }
    }
}
