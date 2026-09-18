import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"

ColumnLayout {
    id: root
    required property var theme
    required property AudioService audio
    required property NetworkService network
    spacing: 14

    MonoText { theme: root.theme; text: "AUDIO"; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
    RowLayout {
        Layout.fillWidth: true
        MonoText { theme: root.theme; Layout.fillWidth: true; font.pixelSize: 26; text: root.audio.available ? Math.round(root.audio.volume * 100) + "%" : "—" }
        TextButton { theme: root.theme; text: root.audio.muted ? "󰝟" : "󰕾"; active: root.audio.muted; interactive: root.audio.available; onClicked: root.audio.setMuted(!root.audio.muted) }
    }
    Rectangle {
        id: volumeBar
        Layout.fillWidth: true
        implicitHeight: 24
        color: "transparent"
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 5; radius: 2.5
            color: root.theme.colors.frame
            Rectangle { width: parent.width * root.audio.volume; height: parent.height; radius: parent.radius; color: root.audio.muted ? root.theme.colors.textMuted : root.theme.colors.textSecondary }
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.audio.available
            cursorShape: Qt.PointingHandCursor
            function updateVolume(x) { root.audio.setVolume(x / width) }
            onPressed: event => updateVolume(event.x)
            onPositionChanged: event => { if (pressed) updateVolume(event.x) }
            onWheel: event => root.audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }
    MonoText {
        theme: root.theme
        Layout.fillWidth: true
        elide: Text.ElideRight
        font.pixelSize: 12
        tone: root.theme.colors.textMuted
        text: root.audio.available ? root.audio.sink.description || root.audio.sink.name : "音訊裝置不可用"
    }
    Item { implicitHeight: 14 }
    MonoText { theme: root.theme; text: "NETWORK"; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
    MonoText { theme: root.theme; text: !root.network.available ? "狀態不可用" : root.network.offline ? "離線" : root.network.connectedDevice ? "已連線" : "未連線" }
    MonoText { theme: root.theme; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 12; tone: root.theme.colors.textMuted; text: root.network.interfaceName }
}
