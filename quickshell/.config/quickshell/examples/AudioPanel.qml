import QtQuick
import "../components"
import "../services"

GlassFrame {
    id: root
    required property AudioService audio
    implicitWidth: 300
    implicitHeight: 60

    MonoText {
        theme: root.theme
        anchors.left: parent.left
        anchors.leftMargin: root.theme.geometry.outerPadding
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: root.theme.typography.bodySize
        text: !root.audio.available ? "Audio unavailable"
            : root.audio.muted ? "Muted" : Math.round(root.audio.volume * 100) + "%"
    }
    IconButton {
        theme: root.theme
        anchors.right: parent.right
        anchors.rightMargin: root.theme.geometry.outerPadding
        anchors.verticalCenter: parent.verticalCenter
        name: "muted"
        active: root.audio.muted
        enabled: root.audio.available
        wheelEnabled: true
        onClicked: root.audio.setMuted(!root.audio.muted)
        onWheel: event => root.audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}
