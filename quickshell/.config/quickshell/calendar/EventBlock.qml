import QtQuick
import "../sidebar/Calendar.js" as Calendar

// One event in the week grid, filled with its calendar's low-saturation tint.
Rectangle {
    id: root
    required property var theme
    required property var event
    property bool selected: false
    property bool compact: false
    readonly property color tint: Calendar.sourceColor(event.calendar || "local", theme.app.sourceColors)
    signal activated()

    radius: theme.app.eventRadius
    color: Qt.rgba(tint.r, tint.g, tint.b, selected ? 0.42 : mouse.containsMouse ? 0.32 : 0.24)
    border.width: selected ? 1 : 0
    border.color: tint
    clip: true

    Column {
        x: 6
        y: root.compact ? 0 : 3
        width: parent.width - 10
        UiText {
            theme: root.theme
            width: parent.width
            height: root.compact ? root.height : implicitHeight
            verticalAlignment: Text.AlignVCenter
            text: root.event.title
            elide: Text.ElideRight
            wrapMode: root.compact ? Text.NoWrap : Text.Wrap
            maximumLineCount: root.compact ? 1 : Math.max(1, Math.floor((root.height - 18) / 16))
            font.pixelSize: 12
            color: root.theme.colors.textPrimary
        }
        UiText {
            theme: root.theme
            visible: !root.compact && root.height >= 34
            mono: true
            text: Calendar.formatMinutes(root.event.startMin)
            font.pixelSize: 10
            color: Qt.lighter(root.tint, 1.25)
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
