import QtQuick

InteractiveSurface {
    id: root
    required property string name
    property int iconSize: theme.geometry.iconSize
    property real lineWidth: theme.geometry.iconStrokeWidth
    property color iconColor: active ? theme.colors.textPrimary : theme.colors.textSecondary

    MonoIcon {
        theme: root.theme
        anchors.centerIn: parent
        width: root.iconSize
        height: width
        name: root.name
        color: root.iconColor
        lineWidth: root.lineWidth
    }
}
