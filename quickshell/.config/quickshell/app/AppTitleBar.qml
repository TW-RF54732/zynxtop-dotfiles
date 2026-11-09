import QtQuick

// App-window title bar: bold title, muted subtitle, actions (children) on the right.
// Pressing the empty bar emits `moveRequested` so the window can call startSystemMove().
Item {
    id: root
    required property var theme
    property string title: ""
    property string subtitle: ""
    default property alias actions: actionRow.data
    signal moveRequested()
    signal doubleClicked()

    height: theme.app.titleBarHeight

    MouseArea {
        anchors.fill: parent
        onPressed: root.moveRequested()
        onDoubleClicked: root.doubleClicked()
    }
    Row {
        x: 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        UiText {
            theme: root.theme
            anchors.baseline: subtitleText.baseline
            text: root.title
            font.pixelSize: 17
            font.bold: true
            color: root.theme.colors.textPrimary
        }
        UiText {
            id: subtitleText
            theme: root.theme
            anchors.verticalCenter: parent.verticalCenter
            text: root.subtitle
            font.pixelSize: 12
            color: root.theme.colors.textMuted
        }
    }
    Row {
        id: actionRow
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
    }
}
