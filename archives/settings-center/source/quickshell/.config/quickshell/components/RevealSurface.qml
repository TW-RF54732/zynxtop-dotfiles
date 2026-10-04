import QtQuick

Item {
    id: root
    required property var theme
    property bool shown: false
    property real expandedWidth: 0
    property real expandedHeight: 0
    width: shown ? expandedWidth : 0
    height: expandedHeight
    opacity: shown ? 1 : 0
    clip: true
    Behavior on width {
        NumberAnimation { duration: root.theme.motion.fastDuration; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        NumberAnimation { duration: root.theme.motion.fastDuration; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: root.theme.motion.fastDuration; easing.type: Easing.OutCubic }
    }
}
