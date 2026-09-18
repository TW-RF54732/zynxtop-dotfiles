import QtQuick

Item {
    id: root
    required property var theme
    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real targetHeight: 0
    property bool inset: false
    property bool animate: true
    property int duration: theme.motion.selectionDuration
    property color fillColor: theme.colors.frame
    property bool ready: false
    x: targetX
    y: targetY
    width: targetWidth
    height: targetHeight

    Component.onCompleted: Qt.callLater(() => root.ready = true)
    Behavior on x { enabled: root.ready && root.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: root.ready && root.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: root.ready && root.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: root.ready && root.animate; NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        visible: !root.inset
        radius: root.theme.geometry.cornerRadius
        color: root.fillColor
    }
    InsetHighlight {
        anchors.fill: parent
        visible: root.inset
        theme: root.theme
        fillColor: root.fillColor
    }
}
