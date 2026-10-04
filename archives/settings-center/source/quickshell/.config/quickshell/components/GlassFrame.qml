import QtQuick

Rectangle {
    required property var theme
    clip: true
    radius: theme.geometry.cornerRadius
    color: theme.colors.surface
    border.width: theme.geometry.frameWidth
    border.color: theme.colors.frame
}
