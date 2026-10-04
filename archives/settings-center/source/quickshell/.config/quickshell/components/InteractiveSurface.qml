import QtQuick

Rectangle {
    id: root
    required property var theme
    property bool active: false
    property bool interactive: true
    property bool wheelEnabled: false
    property bool hoverEnabled: false
    readonly property bool hovered: mouse.containsMouse
    signal clicked()
    signal entered()
    signal wheel(var event)
    implicitWidth: theme.geometry.controlSize
    implicitHeight: theme.geometry.controlSize
    radius: theme.geometry.cornerRadius
    color: active ? theme.colors.frame : "transparent"

    Behavior on color { ColorAnimation { duration: root.theme.motion.fastDuration } }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.hoverEnabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onEntered: root.entered()
        onWheel: event => {
            if (root.wheelEnabled) root.wheel(event)
            else event.accepted = false
        }
    }
}
