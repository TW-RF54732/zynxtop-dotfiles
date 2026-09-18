import QtQuick

Rectangle {
    required property var theme
    height: theme.geometry.separatorHeight
    color: theme.colors.separator
}
