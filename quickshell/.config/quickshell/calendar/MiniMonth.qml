pragma ComponentBehavior: Bound
import QtQuick
import "../app"
import "../sidebar/Calendar.js" as Calendar

// Compact month grid: the window sidebar's week navigator and the editor's date picker.
// `weekStart` draws a band over that week; `selectedKey` fills that day (today is outlined then).
Column {
    id: root
    required property var theme
    required property string todayKey
    property string selectedKey: ""
    property string weekStart: ""
    property int year: 2026
    property int month: 0
    property int cellHeight: 24
    readonly property var cells: Calendar.monthCells(year, month)
    readonly property real cellWidth: width / 7
    readonly property int bandIndex: weekStart === "" ? -1 : cells.findIndex(cell => Calendar.cellKey(cell) === weekStart)
    signal picked(string dateKey)

    function showDate(key) {
        const date = Calendar.parseKey(key);
        year = date.getUTCFullYear();
        month = date.getUTCMonth();
    }
    function step(delta) {
        const index = year * 12 + month + delta;
        year = Math.floor(index / 12);
        month = index - year * 12;
    }

    spacing: 4

    Item {
        width: root.width
        height: 24
        UiText {
            theme: root.theme
            anchors.verticalCenter: parent.verticalCenter
            text: root.year + " 年 " + (root.month + 1) + " 月"
            color: root.theme.colors.textPrimary
            font.bold: true
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: [-1, 1]
                Rectangle {
                    id: arrow
                    required property int modelData
                    width: 22; height: 22
                    radius: root.theme.app.eventRadius
                    color: arrowMouse.containsMouse ? root.theme.app.hover : "transparent"
                    UiText {
                        theme: root.theme
                        anchors.centerIn: parent
                        text: arrow.modelData < 0 ? "‹" : "›"
                        font.pixelSize: 15
                    }
                    MouseArea {
                        id: arrowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.step(arrow.modelData)
                    }
                }
            }
        }
    }

    Row {
        Repeater {
            model: Calendar.WEEKDAYS
            UiText {
                required property string modelData
                theme: root.theme
                width: root.cellWidth
                height: 18
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: 10
                color: root.theme.colors.textMuted
            }
        }
    }

    Item {
        width: root.width
        height: root.cellHeight * 6

        Rectangle {
            visible: root.bandIndex >= 0
            y: Math.floor(root.bandIndex / 7) * root.cellHeight + 1
            width: parent.width
            height: root.cellHeight - 2
            radius: root.theme.app.eventRadius
            color: root.theme.app.hover
        }

        Grid {
            columns: 7
            Repeater {
                model: root.cells
                Item {
                    id: cell
                    required property var modelData
                    readonly property string key: Calendar.cellKey(modelData)
                    readonly property bool inMonth: modelData.month === root.month
                    readonly property bool isToday: key === root.todayKey
                    readonly property bool filled: root.selectedKey !== "" ? key === root.selectedKey : isToday
                    width: root.cellWidth
                    height: root.cellHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 2
                        height: width
                        radius: width / 2
                        visible: cell.filled || (cell.isToday && root.selectedKey !== "") || cellMouse.containsMouse
                        color: cell.filled ? root.theme.colors.textPrimary
                            : cellMouse.containsMouse ? root.theme.app.hover : "transparent"
                        border.width: cell.isToday && !cell.filled ? 1 : 0
                        border.color: root.theme.colors.textMuted
                    }
                    UiText {
                        theme: root.theme
                        anchors.centerIn: parent
                        mono: true
                        text: cell.modelData.day
                        font.pixelSize: 11
                        font.bold: cell.filled
                        color: cell.filled ? root.theme.app.surface
                            : cell.inMonth ? root.theme.colors.textSecondary : root.theme.colors.textMuted
                        opacity: cell.inMonth || cell.filled ? 1 : 0.55
                    }
                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.picked(cell.key)
                    }
                }
            }
        }
    }
}
