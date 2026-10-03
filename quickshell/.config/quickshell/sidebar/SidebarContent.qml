pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../components"
import "../dashboard"

ColumnLayout {
    id: root
    required property var theme
    required property var user
    required property var clock
    required property var notifications
    property list<Component> widgets: []
    spacing: 16
    function resetCalendar() { calendar.reset(); }

    Flickable {
        objectName: "sidebarUpperScroll"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(upper.implicitHeight, root.height * 0.55)
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
            CalendarPanel { id: calendar; theme: root.theme; today: root.clock.displayDate; Layout.fillWidth: true }
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
    NotificationCenter {
        objectName: "sidebarNotifications"
        theme: root.theme
        notifications: root.notifications
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 0
    }
}
