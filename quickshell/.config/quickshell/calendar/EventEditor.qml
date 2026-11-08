pragma ComponentBehavior: Bound
import QtQuick
import "../sidebar/Calendar.js" as Calendar

// Sentence-style event card: a large title and one line per property, no field labels.
// Date/time/repeat are tokens (click or wheel); moving the start keeps the duration.
// Read-only events (subscriptions) show the same layout without editing.
Rectangle {
    id: root
    objectName: "calendarEventEditor"
    required property var theme
    required property string todayKey
    property bool readOnly: false
    property bool editing: false
    property bool saving: false
    property string error: ""
    property bool series: false
    property string calendarId: "local"
    property string calendarName: "本機"
    // Form values.
    property string date: todayKey
    property bool allDay: false
    property int days: 1
    property int startMin: 9 * 60
    property int endMin: 10 * 60
    property string repeat: ""
    property alias title: titleField.text
    property alias location: locationField.text
    property alias notes: notesField.text
    property bool pickingDate: false
    readonly property int snap: theme.calendarWindow.snapMinutes
    readonly property color tint: Calendar.sourceColor(calendarId, theme.app.sourceColors)
    signal saveRequested()
    signal deleteRequested()
    signal cancelRequested()

    function fill(event) {
        readOnly = event.readOnly === true;
        title = event.title || "";
        date = event.date || todayKey;
        allDay = event.allDay === true;
        days = event.days || 1;
        startMin = !allDay && event.startMin !== undefined ? event.startMin : 9 * 60;
        endMin = !allDay && event.endMin !== undefined ? event.endMin : startMin + 60;
        repeat = event.repeat || "";
        location = event.location || "";
        notes = event.description || "";
        calendarId = event.calendar || "local";
        calendarName = event.calendarName || "本機";
        series = !!(event.repeat || event.recurring);
        pickingDate = false;
        startToken.typing = false;
        endToken.typing = false;
    }
    // {error} when invalid, else {event} in the backend's create/update shape.
    function collect() {
        if (!title.trim()) return {error: "請輸入標題"};
        if (!allDay && endMin <= startMin) return {error: "結束時間需晚於開始時間"};
        return {event: {
            title: title.trim(), date: date, allDay: allDay, days: days,
            startMin: startMin, endMin: endMin, location: location.trim(),
            description: notes, repeat: repeat
        }};
    }
    function setStart(minutes) {
        const length = endMin - startMin;
        startMin = Math.max(0, Math.min(24 * 60 - snap, minutes));
        endMin = Math.min(24 * 60, startMin + Math.max(snap, length));
    }
    function setEnd(minutes) { endMin = Math.max(startMin + snap, Math.min(24 * 60, minutes)); }
    function focusTitle() { if (!readOnly) titleField.focusInput(); }
    // Esc first leaves typing or the date picker; returns true if it did.
    function dismissInner() {
        if (startToken.typing || endToken.typing) {
            startToken.typing = false;
            endToken.typing = false;
            return true;
        }
        if (pickingDate) { pickingDate = false; return true; }
        return false;
    }

    width: theme.calendarWindow.editorWidth
    height: body.implicitHeight + 32
    radius: theme.app.cardRadius
    color: theme.app.raised
    border.width: 1
    border.color: theme.app.raisedBorder

    // Clicks inside the card stay in the card.
    MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

    component Icon: Text {
        required property var theme
        width: 16
        horizontalAlignment: Text.AlignHCenter
        color: theme.colors.textMuted
        font.family: theme.typography.family
        font.pixelSize: 12
    }

    Column {
        id: body
        x: 18; y: 16
        width: root.width - 36
        spacing: 11

        LineField {
            id: titleField
            objectName: "calendarTitleField"
            theme: root.theme
            width: parent.width
            readOnly: root.readOnly
            placeholder: "新事項"
            pixelSize: 19
            bold: true
            alwaysUnderline: !root.readOnly
            onAccepted: root.saveRequested()
        }

        // Date and time.
        Row {
            spacing: 10
            Icon { theme: root.theme; text: ""; anchors.verticalCenter: parent.verticalCenter }
            Token {
                objectName: "calendarDateToken"
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                text: Calendar.shortDate(root.date)
                interactive: !root.readOnly
                active: root.pickingDate
                onClicked: {
                    datePicker.showDate(root.date);
                    root.pickingDate = !root.pickingDate;
                }
                onStepped: direction => root.date = Calendar.addDays(root.date, direction)
            }
            TimeToken {
                id: startToken
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.allDay
                minutes: root.startMin
                interactive: !root.readOnly
                onStepped: direction => root.setStart(root.startMin + direction * root.snap)
                onTyped: minutes => root.setStart(minutes)
            }
            UiText {
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.allDay
                text: "→"
                color: root.theme.colors.textMuted
            }
            TimeToken {
                id: endToken
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.allDay
                minutes: root.endMin
                interactive: !root.readOnly
                onStepped: direction => root.setEnd(root.endMin + direction * root.snap)
                onTyped: minutes => root.setEnd(minutes)
            }
            UiText {
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                visible: root.allDay
                text: "全天"
                color: root.theme.colors.textPrimary
            }
            Token {
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                visible: root.allDay && (!root.readOnly || root.days > 1)
                text: "共 " + root.days + " 天"
                interactive: !root.readOnly
                textColor: root.theme.colors.textSecondary
                onClicked: root.days = root.days % 14 + 1
                onStepped: direction => root.days = Math.max(1, Math.min(60, root.days + direction))
            }
        }
        Row {
            x: 26
            spacing: 6
            visible: !root.readOnly
            UiText {
                theme: root.theme
                visible: !root.allDay
                text: Calendar.durationLabel(root.endMin - root.startMin) + " ·"
                font.pixelSize: 12
                color: root.theme.colors.textMuted
            }
            Token {
                objectName: "calendarAllDayToggle"
                theme: root.theme
                text: root.allDay ? "改為指定時間" : "全天"
                textColor: root.theme.colors.textMuted
                onClicked: root.allDay = !root.allDay
            }
        }
        MiniMonth {
            id: datePicker
            x: 26
            width: parent.width - 26
            visible: root.pickingDate
            theme: root.theme
            todayKey: root.todayKey
            selectedKey: root.date
            cellHeight: 26
            onPicked: key => {
                root.date = key;
                root.pickingDate = false;
            }
        }

        // Repeat.
        Column {
            width: parent.width
            spacing: 3
            visible: !root.readOnly || root.series
            Row {
                spacing: 10
                Icon { theme: root.theme; text: ""; anchors.verticalCenter: parent.verticalCenter }
                Token {
                    objectName: "calendarRepeatToken"
                    theme: root.theme
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.readOnly ? "重複事項" : Calendar.repeatLabel(root.repeat, root.date)
                    interactive: !root.readOnly
                    textColor: root.repeat || root.readOnly ? root.theme.colors.textPrimary : root.theme.colors.textMuted
                    onClicked: root.repeat = Calendar.stepRepeat(root.repeat, 1)
                    onStepped: direction => root.repeat = Calendar.stepRepeat(root.repeat, direction)
                }
            }
            UiText {
                theme: root.theme
                x: 26
                visible: root.editing && root.series && !root.readOnly
                text: "修改會套用到整個系列"
                font.pixelSize: 11
                color: root.theme.colors.textMuted
            }
        }

        // Location.
        Row {
            spacing: 10
            visible: !root.readOnly || root.location !== ""
            Icon { theme: root.theme; text: ""; anchors.verticalCenter: parent.verticalCenter }
            LineField {
                id: locationField
                theme: root.theme
                width: body.width - 26
                readOnly: root.readOnly
                placeholder: "加地點"
                onAccepted: root.saveRequested()
            }
        }

        // Notes.
        Row {
            spacing: 10
            visible: !root.readOnly || root.notes !== ""
            Icon { theme: root.theme; text: ""; y: 2 }
            Flickable {
                width: body.width - 26
                height: Math.min(Math.max(notesField.implicitHeight, 20), 110)
                contentHeight: notesField.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                TextEdit {
                    id: notesField
                    width: parent.width
                    readOnly: root.readOnly
                    wrapMode: TextEdit.Wrap
                    color: root.theme.colors.textSecondary
                    selectionColor: root.theme.colors.textSelection
                    selectedTextColor: root.theme.colors.textPrimary
                    font.family: root.theme.app.uiFamily
                    font.pixelSize: 13
                    selectByMouse: true
                    UiText {
                        theme: root.theme
                        visible: notesField.text === "" && !notesField.activeFocus
                        text: "加備註"
                        color: root.theme.colors.textMuted
                    }
                }
            }
        }

        // Source calendar.
        Row {
            spacing: 10
            Item {
                width: 16; height: 16
                Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 3; color: root.tint }
            }
            UiText {
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                text: root.calendarName + (root.readOnly ? " · 唯讀" : "")
                color: root.theme.colors.textSecondary
            }
        }

        UiText {
            objectName: "calendarFormError"
            theme: root.theme
            width: parent.width
            visible: root.error !== ""
            text: root.error
            wrapMode: Text.Wrap
            font.pixelSize: 12
            color: root.theme.colors.textPrimary
        }

        Rectangle { width: parent.width; height: 1; color: root.theme.app.raisedBorder }

        Item {
            width: parent.width
            height: 30
            AppButton {
                objectName: "calendarDeleteButton"
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                x: -8
                visible: root.editing && !root.readOnly
                text: "刪除"
                interactive: !root.saving
                onClicked: root.deleteRequested()
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                UiText {
                    theme: root.theme
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.readOnly ? "Esc 關閉" : "Esc 取消"
                    font.pixelSize: 11
                    color: root.theme.colors.textMuted
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancelRequested()
                    }
                }
                AppButton {
                    objectName: "calendarSaveButton"
                    theme: root.theme
                    visible: !root.readOnly
                    primary: true
                    text: root.saving ? "儲存中…" : "儲存"
                    interactive: !root.saving
                    onClicked: root.saveRequested()
                }
            }
        }
    }
}
