import QtQuick

// A clickable word in a sentence-style form: underlined on hover, click and wheel to change.
Item {
    id: root
    required property var theme
    property string text: ""
    property bool mono: false
    property bool interactive: true
    property bool active: false
    property color textColor: theme.colors.textPrimary
    signal clicked()
    signal stepped(int direction)

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight + 3

    UiText {
        id: label
        theme: root.theme
        mono: root.mono
        text: root.text
        color: root.textColor
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: root.active ? root.theme.colors.textSecondary
            : mouse.containsMouse ? root.theme.colors.textMuted : "transparent"
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -3
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: wheel => {
            const delta = wheel.angleDelta.y || -wheel.angleDelta.x;
            if (delta !== 0) root.stepped(delta > 0 ? 1 : -1);
        }
    }
}
