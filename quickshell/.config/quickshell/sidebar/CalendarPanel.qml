pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../components"
import "Calendar.js" as Calendar

ColumnLayout {
    id: root
    objectName: "sidebarCalendar"
    required property var theme
    required property date today
    property int displayedYear: today.getFullYear()
    property int displayedMonth: today.getMonth()
    readonly property var cells: Calendar.monthCells(displayedYear, displayedMonth)
    // "YYYY-MM-DD" of the selected day, and a {key: true} set of days that have events.
    property string selectedKey: ""
    property var markedDays: ({})
    signal daySelected(var cell)
    spacing: 6

    function reset() {
        displayedYear = today.getFullYear();
        displayedMonth = today.getMonth();
    }
    function stepMonth(delta) {
        const next = new Date(Date.UTC(displayedYear, displayedMonth + delta, 1));
        displayedYear = next.getUTCFullYear();
        displayedMonth = next.getUTCMonth();
    }

    RowLayout {
        Layout.fillWidth: true
        MonoText {
            theme: root.theme
            text: root.displayedYear + " / " + String(root.displayedMonth + 1).padStart(2, "0")
            Layout.fillWidth: true
        }
        TextButton {
            theme: root.theme; text: "‹"
            Accessible.name: "上一個月"
            onClicked: root.stepMonth(-1)
        }
        TextButton {
            theme: root.theme; text: "今天"
            onClicked: root.reset()
        }
        TextButton {
            theme: root.theme; text: "›"
            objectName: "nextMonthButton"
            Accessible.name: "下一個月"
            onClicked: root.stepMonth(1)
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 2
        rowSpacing: 2
        Repeater {
            model: ["一", "二", "三", "四", "五", "六", "日"]
            MonoText {
                required property string modelData
                theme: root.theme
                text: modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                tone: root.theme.colors.textMuted
            }
        }
        Repeater {
            model: root.cells
            Rectangle {
                required property var modelData
                readonly property bool isToday: Calendar.sameDay(modelData, root.today)
                readonly property string key: Calendar.cellKey(modelData)
                readonly property bool isSelected: key === root.selectedKey
                Layout.fillWidth: true
                Layout.preferredWidth: 36
                Layout.preferredHeight: 30
                radius: root.theme.geometry.cornerRadius
                color: isToday ? root.theme.colors.frame : "transparent"
                border.width: isToday || isSelected ? 1 : 0
                border.color: isToday ? root.theme.colors.textSecondary : root.theme.colors.textMuted
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.daySelected(parent.modelData)
                }
                Rectangle {
                    width: 3; height: 3; radius: 1.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    color: root.theme.colors.textMuted
                    visible: root.markedDays[parent.key] === true
                }
                MonoText {
                    theme: root.theme
                    anchors.centerIn: parent
                    text: parent.modelData.day
                    font.pixelSize: 13
                    tone: parent.isToday ? root.theme.colors.textPrimary
                        : parent.modelData.month === root.displayedMonth
                            ? root.theme.colors.textSecondary : root.theme.colors.textMuted
                }
            }
        }
    }
}
