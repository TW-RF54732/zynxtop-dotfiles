pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../components"
import "Calendar.js" as Calendar

// Fixed-height day agenda: event list on the left, 24-hour timeline on the right.
ColumnLayout {
    id: root
    objectName: "sidebarAgenda"
    required property var theme
    // {year, month (0-based), day} of the selected day.
    required property var selectedDay
    property bool isToday: false
    property int nowMinute: 0
    property var events: []
    property string selectedKey: ""
    property string status: ""
    signal eventActivated(var event)
    signal addRequested()
    spacing: 8

    function scrollToFocus() { timeline.scrollToFocus(); }

    RowLayout {
        Layout.fillWidth: true
        spacing: 4
        MonoText {
            theme: root.theme
            Layout.fillWidth: true
            text: Calendar.pad2(root.selectedDay.month + 1) + "/" + Calendar.pad2(root.selectedDay.day) + " · "
                + ["週日", "週一", "週二", "週三", "週四", "週五", "週六"][
                    new Date(Date.UTC(root.selectedDay.year, root.selectedDay.month, root.selectedDay.day)).getUTCDay()]
                + (root.isToday ? " · 今天" : "")
            font.pixelSize: 13
            tone: root.theme.colors.textSecondary
        }
        MonoText {
            theme: root.theme
            visible: root.status !== ""
            text: root.status
            font.pixelSize: 11
            tone: root.theme.colors.textMuted
        }
        TextButton {
            objectName: "agendaAddButton"
            theme: root.theme
            text: "+"
            implicitHeight: 26
            implicitWidth: 26
            Accessible.name: "新增事項"
            onClicked: root.addRequested()
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12
        AgendaList {
            theme: root.theme
            events: root.events
            selectedKey: root.selectedKey
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            onEventActivated: event => {
                timeline.scrollToEvent(event);
                root.eventActivated(event);
            }
        }
        AgendaTimeline {
            id: timeline
            theme: root.theme
            events: root.events
            selectedKey: root.selectedKey
            showNow: root.isToday
            nowMinute: root.nowMinute
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            onEventActivated: event => root.eventActivated(event)
        }
    }
}
