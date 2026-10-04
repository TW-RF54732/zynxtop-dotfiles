import QtQuick
import "../components"

Item {
    id: root

    required property var theme
    required property var activeWindow
    required property var windows
    property var pinnedWindow: null
    readonly property bool pinned: pinnedWindow !== null && windows.indexOf(pinnedWindow) !== -1
    readonly property var displayedWindow: pinned ? pinnedWindow : activeWindow
    readonly property string title: displayedWindow ? displayedWindow.title : ""

    onWindowsChanged: {
        if (pinnedWindow !== null && windows.indexOf(pinnedWindow) === -1)
            pinnedWindow = null
    }

    function togglePin() {
        pinnedWindow = pinned ? null : activeWindow
    }

    visible: title.length > 0
    implicitWidth: label.implicitWidth
    implicitHeight: theme.topBar.height

    MonoText {
        id: label
        theme: root.theme
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        tone: root.theme.colors.textSecondary
        font.pixelSize: root.theme.topBar.textSize
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Rectangle {
        anchors.horizontalCenter: label.horizontalCenter
        y: label.y + label.height + 2
        width: Math.min(label.implicitWidth, label.width)
        height: 1
        color: label.color
        opacity: root.pinned ? 1 : mouse.containsMouse ? 0.35 : 0

        Behavior on opacity {
            NumberAnimation { duration: root.theme.motion.fastDuration }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePin()
    }
}
