pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "Calendar.js" as Calendar

// Left half of the agenda: the selected day's events as rows, all-day first.
Item {
    id: root
    objectName: "agendaList"
    required property var theme
    property var events: []
    property string selectedKey: ""
    readonly property var sorted: Calendar.sortEvents(events)
    signal eventActivated(var event)

    MonoText {
        theme: root.theme
        anchors.centerIn: parent
        visible: root.sorted.length === 0
        text: "EMPTY"
        font.pixelSize: root.theme.typography.detailSize
        tone: root.theme.colors.textMuted
    }
    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.sorted
        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property bool selected: modelData.key === root.selectedKey
            width: list.width
            height: root.theme.sidebar.agendaRowHeight
            radius: root.theme.geometry.cornerRadius
            color: selected || mouse.containsMouse ? root.theme.colors.frame : "transparent"
            Behavior on color { ColorAnimation { duration: root.theme.motion.fastDuration } }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 8
                width: parent.width - 16
                spacing: 2
                MonoText {
                    theme: root.theme
                    width: parent.width
                    text: row.modelData.title
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    tone: row.selected ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                }
                MonoText {
                    theme: root.theme
                    width: parent.width
                    text: Calendar.timeLabel(row.modelData)
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    tone: root.theme.colors.textMuted
                }
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.eventActivated(row.modelData)
            }
        }
    }
}
