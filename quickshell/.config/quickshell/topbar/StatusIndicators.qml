import QtQuick
import Quickshell.Networking
import Quickshell.Services.Pipewire
import "../components"

Row {
    id: root

    required property var theme
    spacing: theme.topBar.itemSpacing / 2

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink !== null && sink.audio !== null && sink.audio.muted
    readonly property bool offline: Networking.backend !== NetworkBackendType.None
        && Networking.connectivity === NetworkConnectivity.None

    PwObjectTracker {
        objects: root.sink !== null ? [root.sink] : []
    }

    Rectangle {
        width: root.theme.topBar.statusHitSize
        height: root.theme.topBar.height
        color: "transparent"
        visible: root.offline

        MonoIcon {
            anchors.centerIn: parent
            width: root.theme.topBar.iconSize
            height: width
            name: "offline"
            color: root.theme.colors.status
            lineWidth: root.theme.topBar.iconStrokeWidth
        }
    }

    Rectangle {
        width: root.theme.topBar.statusHitSize
        height: root.theme.topBar.height
        color: "transparent"
        visible: root.muted

        MonoIcon {
            anchors.centerIn: parent
            width: root.theme.topBar.iconSize
            height: width
            name: "muted"
            color: root.theme.colors.status
            lineWidth: root.theme.topBar.iconStrokeWidth
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.sink !== null && root.sink.audio !== null)
                    root.sink.audio.muted = false
            }
            onWheel: event => {
                if (root.sink === null || root.sink.audio === null)
                    return
                const step = event.angleDelta.y > 0 ? 0.05 : -0.05
                root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
            }
        }
    }
}
