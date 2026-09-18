import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../components"

ColumnLayout {
    id: root
    required property var theme
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    spacing: 14
    MonoText { theme: root.theme; text: "MEDIA"; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
    RowLayout {
        spacing: 16
        Rectangle {
            implicitWidth: 64; implicitHeight: 64; radius: 5; color: root.theme.colors.frame
            Image { anchors.fill: parent; source: root.player ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectFit; asynchronous: true }
            MonoText { theme: root.theme; anchors.centerIn: parent; text: "♪"; visible: !root.player || !root.player.trackArtUrl; tone: root.theme.colors.textMuted; font.pixelSize: 28 }
        }
        ColumnLayout {
            Layout.fillWidth: true
            MonoText { theme: root.theme; Layout.fillWidth: true; elide: Text.ElideRight; text: root.player ? root.player.trackTitle || root.player.identity : "沒有播放中的媒體" }
            MonoText { theme: root.theme; Layout.fillWidth: true; elide: Text.ElideRight; text: root.player ? root.player.trackArtist || root.player.identity : ""; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
        }
    }
    Row {
        spacing: 8
        TextButton { theme: root.theme; text: "󰒮"; interactive: !!root.player && root.player.canGoPrevious; onClicked: root.player.previous() }
        TextButton { theme: root.theme; text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"; interactive: !!root.player && root.player.canTogglePlaying; onClicked: root.player.togglePlaying() }
        TextButton { theme: root.theme; text: "󰒭"; interactive: !!root.player && root.player.canGoNext; onClicked: root.player.next() }
    }
}
