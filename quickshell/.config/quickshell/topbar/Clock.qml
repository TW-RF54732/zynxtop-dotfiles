import QtQuick
import "../services"
import "../components"

Row {
    id: root

    required property var theme
    spacing: theme.topBar.itemSpacing
    required property ClockService clock

    MonoText {
        id: dateText
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

    MonoText {
        id: timeText
        theme: root.theme
        // Digits sit on the same baseline as the date text.
        anchors.baseline: dateText.baseline
        text: root.clock.timeText
        tone: root.theme.colors.textPrimary
        font.pixelSize: root.theme.topBar.clockSize
        font.bold: true
        // Widen the slot so the underline extends past the digits on both sides.
        width: implicitWidth + root.theme.topBar.clockProgressOverhang * 2
        horizontalAlignment: Text.AlignHCenter

        // Elapsed share of the 24-hour day, drawn as an underline just below the digits.
        Rectangle {
            anchors.top: parent.baseline
            anchors.topMargin: root.theme.topBar.clockProgressGap
            width: parent.width
            height: root.theme.topBar.clockProgressHeight
            radius: height / 2
            color: root.theme.colors.separator

            Rectangle {
                width: Math.round(parent.width * root.clock.dayProgress)
                height: parent.height
                radius: parent.radius
                color: root.theme.colors.textSecondary
            }
        }
    }

}
