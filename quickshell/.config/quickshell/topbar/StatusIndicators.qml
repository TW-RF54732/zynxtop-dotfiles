import QtQuick
import "../components"
import "../services"

Row {
    id: root
    required property var theme
    required property AudioService audio
    required property NetworkService network
    spacing: theme.topBar.itemSpacing / 2

    IconButton {
        theme: root.theme
        width: root.theme.topBar.statusHitSize
        height: root.theme.topBar.height
        visible: root.network.offline
        interactive: false
        name: "offline"
        iconSize: root.theme.topBar.iconSize
        iconColor: root.theme.colors.status
        lineWidth: root.theme.topBar.iconStrokeWidth
    }
    IconButton {
        theme: root.theme
        width: root.theme.topBar.statusHitSize
        height: root.theme.topBar.height
        visible: root.audio.muted
        wheelEnabled: true
        name: "muted"
        iconSize: root.theme.topBar.iconSize
        iconColor: root.theme.colors.status
        lineWidth: root.theme.topBar.iconStrokeWidth
        onClicked: root.audio.setMuted(false)
        onWheel: event => root.audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}
