import QtQuick

// On/off marker: filled white when `on`, a muted ring otherwise.
Rectangle {
    required property var theme
    property bool on: false
    implicitWidth: 8
    implicitHeight: 8
    radius: width / 2
    color: on ? theme.colors.textPrimary : "transparent"
    border.width: on ? 0 : 1
    border.color: theme.colors.textMuted
}
