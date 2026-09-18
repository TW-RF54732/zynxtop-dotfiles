import QtQuick
import Quickshell
import "../components"

Row {
    id: root

    required property var theme
    spacing: theme.topBar.itemSpacing
    readonly property date displayDate: new Date(clock.date.getTime()
        + clock.date.getTimezoneOffset() * 60 * 1000)
    readonly property bool daytime: displayDate.getHours() >= 6
        && displayDate.getHours() < 18

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MonoText {
        theme: root.theme
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.displayDate, "ddd  MM/dd")
        tone: root.theme.colors.textSecondary
        font.pixelSize: root.theme.topBar.textSize
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.theme.topBar.dividerWidth
        height: root.theme.topBar.dividerHeight
        color: root.theme.colors.separator
    }

    MonoIcon {
        anchors.verticalCenter: parent.verticalCenter
        width: root.theme.topBar.iconSize
        height: width
        name: root.daytime ? "sun" : "moon"
        color: root.theme.colors.textSecondary
        lineWidth: root.theme.topBar.iconStrokeWidth
    }

    MonoText {
        theme: root.theme
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.displayDate, "hh:mm")
        tone: root.theme.colors.textPrimary
        font.pixelSize: root.theme.topBar.clockSize
        font.bold: true
    }

}
