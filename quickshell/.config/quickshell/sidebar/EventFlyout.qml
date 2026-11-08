pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "Calendar.js" as Calendar

// Event detail card split off the Sidebar's left side, styled like the Dashboard flyout.
GlassFrame {
    id: root
    objectName: "sidebarEventFlyout"

    // The event shown; null closes the card. Content stays on the last event while fading.
    property var event: null
    property string dayLabel: ""
    property var content: null
    readonly property bool open: event !== null
    readonly property int pad: theme.sidebar.flyoutPadding
    property real reveal: open ? 1 : 0
    signal editRequested(var event)
    signal deleteRequested(var event)
    signal closeRequested()

    onEventChanged: if (event) content = event

    radius: theme.topBar.radius
    color: theme.colors.topBarSurface
    border.width: theme.topBar.dividerWidth
    border.color: theme.colors.separator
    antialiasing: true
    visible: reveal > 0
    opacity: reveal
    width: theme.sidebar.flyoutWidth
    height: Math.min(theme.sidebar.flyoutMaxHeight, body.implicitHeight + pad * 2)

    Behavior on reveal { NumberAnimation { duration: root.theme.sidebar.flyoutDuration; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: root.open; NumberAnimation { duration: root.theme.sidebar.flyoutDuration; easing.type: Easing.OutCubic } }

    // Clicks inside the card must not reach the window's close-on-outside-click area.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: event => event.accepted = true
        onWheel: event => event.accepted = true
    }

    Column {
        id: body
        x: root.pad; y: root.pad
        width: root.width - root.pad * 2
        spacing: 10
        readonly property var item: root.content || ({})

        MonoText {
            theme: root.theme
            width: parent.width
            text: body.item.title || ""
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.pixelSize: 15
        }
        Column {
            width: parent.width
            spacing: 4
            Repeater {
                model: [
                    body.item.multiDay ? body.item.startLabel.replace(/-/g, "/") + " → " + body.item.endLabel.replace(/-/g, "/")
                        : root.dayLabel + " · " + (body.item.allDay !== undefined ? Calendar.timeLabel(body.item) : ""),
                    (body.item.calendarName || "") + (body.item.readOnly ? " · 唯讀" : "")
                        + (body.item.recurring ? " · 重複" : ""),
                    body.item.location || ""
                ].filter(line => line !== "")
                MonoText {
                    required property string modelData
                    theme: root.theme
                    width: parent.width
                    text: modelData
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    tone: root.theme.colors.textSecondary
                }
            }
        }
        Separator {
            theme: root.theme
            width: parent.width
            visible: notes.text !== ""
        }
        Flickable {
            width: parent.width
            height: Math.min(notes.implicitHeight, 160)
            visible: notes.text !== ""
            contentHeight: notes.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            MonoText {
                id: notes
                theme: root.theme
                width: parent.width
                text: body.item.description || ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                font.pixelSize: 12
                tone: root.theme.colors.textSecondary
            }
        }
        Row {
            visible: body.item.readOnly === false
            spacing: 4
            anchors.right: parent.right
            TextButton {
                objectName: "eventEditButton"
                theme: root.theme
                text: "編輯"
                implicitHeight: 28
                hoverEnabled: true
                active: hovered
                onClicked: root.editRequested(root.content)
            }
            TextButton {
                objectName: "eventDeleteButton"
                theme: root.theme
                text: "刪除"
                implicitHeight: 28
                hoverEnabled: true
                active: hovered
                onClicked: root.deleteRequested(root.content)
            }
        }
    }
}
