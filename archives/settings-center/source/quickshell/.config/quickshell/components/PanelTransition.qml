import QtQuick

Item {
    id: root
    required property var theme
    default property alias contentData: content.data
    property bool shown: false
    // The direction the content moves when appearing; "none" produces a fade.
    property string direction: "down"
    property real distance: theme.geometry.outerPadding / 2
    property int duration: theme.motion.fastDuration
    property real progress: 0
    property bool ready: false
    readonly property bool animating: transition.running
    readonly property real offsetX: direction === "right" ? -distance
        : direction === "left" ? distance : 0
    readonly property real offsetY: direction === "down" ? -distance
        : direction === "up" ? distance : 0
    signal opened()
    signal closed()
    visible: shown || progress > 0
    enabled: shown
    implicitWidth: content.childrenRect.width
    implicitHeight: content.childrenRect.height

    property Item contentItem: Item {
        id: content
        parent: root
        width: root.width
        height: root.height
        opacity: root.progress
        transform: Translate {
            x: root.offsetX * (1 - root.progress)
            y: root.offsetY * (1 - root.progress)
        }
    }

    onShownChanged: if (ready) progress = shown ? 1 : 0
    Component.onCompleted: {
        ready = true
        progress = shown ? 1 : 0
    }
    Behavior on progress {
        enabled: root.ready
        NumberAnimation {
            id: transition
            duration: root.duration
            easing.type: Easing.OutCubic
            onFinished: {
                if (root.shown) root.opened()
                else root.closed()
            }
        }
    }
}
