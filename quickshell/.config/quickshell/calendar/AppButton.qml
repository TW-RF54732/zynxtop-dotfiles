import QtQuick

// App-layer button. `primary` is the one filled action per card; others are plain text.
Rectangle {
    id: root
    required property var theme
    required property string text
    property bool primary: false
    property bool interactive: true
    readonly property bool hovered: mouse.containsMouse
    signal clicked()

    implicitWidth: label.implicitWidth + (primary ? 28 : 16)
    implicitHeight: 30
    radius: theme.app.eventRadius
    color: primary ? (hovered ? theme.colors.textPrimary : theme.colors.textSecondary)
        : (hovered ? theme.app.hover : "transparent")
    opacity: interactive ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: root.theme.motion.fastDuration } }

    UiText {
        id: label
        theme: root.theme
        anchors.centerIn: parent
        text: root.text
        font.bold: root.primary
        color: root.primary ? root.theme.app.surface
            : (root.hovered ? root.theme.colors.textPrimary : root.theme.colors.textSecondary)
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
