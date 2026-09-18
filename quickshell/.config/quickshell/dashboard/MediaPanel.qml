import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../components"

ColumnLayout {
    id: root
    required property var theme
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    // Browsers can briefly omit artwork in later metadata updates for the same video.
    readonly property string artworkTrackKey: player
        ? JSON.stringify([String(player.trackUrl || ""), player.trackTitle || "", player.trackArtist || ""])
        : ""
    property var artworkPlayer: null
    property string artworkKey: ""
    property string artworkUrl: ""
    function updateArtwork() {
        if (artworkPlayer !== player || artworkKey !== artworkTrackKey) {
            artworkPlayer = player
            artworkKey = artworkTrackKey
            artworkUrl = ""
        }
        if (player && player.trackArtUrl)
            artworkUrl = String(player.trackArtUrl)
    }
    onPlayerChanged: updateArtwork()
    onArtworkTrackKeyChanged: updateArtwork()
    Component.onCompleted: updateArtwork()
    Connections {
        target: root.player
        function onTrackArtUrlChanged() { root.updateArtwork() }
    }
    readonly property bool hasProgress: !!player && player.positionSupported && player.lengthSupported && player.length > 0
    function timeLabel(seconds) {
        const total = Math.max(0, Math.floor(seconds))
        return Math.floor(total / 60) + ":" + String(total % 60).padStart(2, "0")
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && !!root.player && root.player.isPlaying && root.hasProgress
        onTriggered: root.player.positionChanged()
    }
    spacing: 6
    MonoText { theme: root.theme; text: "MEDIA"; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
    RowLayout {
        spacing: 16
        Rectangle {
            implicitWidth: 48; implicitHeight: 48; radius: 5; color: root.theme.colors.frame
            Image { id: artwork; anchors.fill: parent; source: root.artworkUrl; fillMode: Image.PreserveAspectFit; asynchronous: true }
            MonoText { theme: root.theme; anchors.centerIn: parent; text: "♪"; visible: artwork.status !== Image.Ready; tone: root.theme.colors.textMuted; font.pixelSize: 28 }
        }
        ColumnLayout {
            Layout.fillWidth: true
            MonoText { theme: root.theme; Layout.fillWidth: true; elide: Text.ElideRight; text: root.player ? root.player.trackTitle || root.player.identity : "沒有播放中的媒體" }
            MonoText { theme: root.theme; Layout.fillWidth: true; elide: Text.ElideRight; text: root.player ? root.player.trackArtist || root.player.identity : ""; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 4
        TextButton { implicitWidth: 30; implicitHeight: 30; theme: root.theme; text: "󰒮"; interactive: !!root.player && root.player.canGoPrevious; onClicked: root.player.previous() }
        TextButton { implicitWidth: 30; implicitHeight: 30; theme: root.theme; text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"; interactive: !!root.player && root.player.canTogglePlaying; onClicked: root.player.togglePlaying() }
        TextButton { implicitWidth: 30; implicitHeight: 30; theme: root.theme; text: "󰒭"; interactive: !!root.player && root.player.canGoNext; onClicked: root.player.next() }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 24
            color: "transparent"
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 4; radius: 2
                color: root.theme.colors.frame
                Rectangle {
                    width: parent.width * (root.hasProgress ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0)
                    height: parent.height; radius: parent.radius
                    color: root.theme.colors.textSecondary
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.hasProgress && root.player.canSeek
                cursorShape: Qt.PointingHandCursor
                function seekTo(x) { root.player.position = Math.max(0, Math.min(1, x / width)) * root.player.length }
                onPressed: event => seekTo(event.x)
                onPositionChanged: event => { if (pressed) seekTo(event.x) }
            }
        }
        MonoText {
            theme: root.theme
            font.pixelSize: 10
            tone: root.theme.colors.textSecondary
            text: root.hasProgress ? root.timeLabel(root.player.position) + " / " + root.timeLabel(root.player.length) : "— / —"
        }
    }
}
