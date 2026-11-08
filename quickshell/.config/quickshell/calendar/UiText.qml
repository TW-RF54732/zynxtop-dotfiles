import QtQuick

// Text for app-layer windows: proportional CJK UI face; `mono` for times and numbers.
Text {
    required property var theme
    property bool mono: false
    color: theme.colors.textSecondary
    font.family: mono ? theme.typography.family : theme.app.uiFamily
    font.pixelSize: 13
    textFormat: Text.PlainText
}
