import QtQuick

Text {
    required property var theme
    property color tone: theme.colors.textPrimary
    color: tone
    font.family: theme.typography.family
}
