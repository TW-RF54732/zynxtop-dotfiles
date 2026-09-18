import QtQuick

Rectangle {
    required property var theme
    property bool vertical: false
    property int thickness: theme.geometry.separatorHeight
    property int length: 20
    implicitWidth: vertical ? thickness : length
    implicitHeight: vertical ? length : thickness
    color: theme.colors.separator
}
