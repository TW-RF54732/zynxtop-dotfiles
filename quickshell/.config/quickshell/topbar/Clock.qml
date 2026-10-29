import QtQuick
import "../services"
import "../components"

Row {
    id: root

    required property var theme
    spacing: theme.topBar.itemSpacing
    required property ClockService clock

    MonoText {
        theme: root.theme
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.clock.displayDate, "ddd  MM/dd")
        tone: root.theme.colors.textSecondary
        font.pixelSize: root.theme.topBar.textSize
    }

    Separator {
        theme: root.theme
        vertical: true
        anchors.verticalCenter: parent.verticalCenter
        width: root.theme.topBar.dividerWidth
        height: root.theme.topBar.dividerHeight
        color: root.theme.colors.separator
    }

    MonoIcon {
        theme: root.theme
        anchors.verticalCenter: parent.verticalCenter
        width: root.theme.topBar.iconSize
        height: width
        name: root.clock.daytime ? "half-top" : "half-bottom"
        color: root.theme.colors.textSecondary
        lineWidth: root.theme.topBar.iconStrokeWidth
    }

    MonoText {
        theme: root.theme
        anchors.verticalCenter: parent.verticalCenter
        text: root.clock.timeText
        tone: root.theme.colors.textPrimary
        font.pixelSize: root.theme.topBar.clockSize
        font.bold: true
    }

}
