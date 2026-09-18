import QtQuick
import "../components"

Rectangle {
    id: root

    required property var theme
    property bool active: false
    signal toggled()

    implicitWidth: theme.topBar.statusHitSize
    implicitHeight: theme.topBar.height
    radius: theme.geometry.cornerRadius
    color: active ? theme.colors.frame : "transparent"

    Behavior on color {
        ColorAnimation { duration: root.theme.motion.fastDuration }
    }

    MonoIcon {
        anchors.centerIn: parent
        width: root.theme.topBar.iconSize
        height: width
        name: "dashboard"
        color: root.active ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
        lineWidth: root.theme.topBar.iconStrokeWidth
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
