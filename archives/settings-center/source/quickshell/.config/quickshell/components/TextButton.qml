import QtQuick

InteractiveSurface {
    id: root
    required property string text
    property color textColor: theme.colors.textSecondary
    implicitWidth: Math.max(theme.geometry.controlSize, label.implicitWidth + 16)
    MonoText {
        id: label
        theme: root.theme
        anchors.centerIn: parent
        text: root.text
        tone: root.textColor
        opacity: root.interactive ? 1 : 0.35
    }
}
