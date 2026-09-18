import QtQuick
import QtQuick.Layouts
import "components"
import "dashboard"
import "services"

GlassFrame {
    id: root
    required property SystemStatusService systemStatus
    required property SystemStatsService systemStats
    required property AudioService audio
    required property NetworkService network
    function diskCapacity() {
        const stats = systemStats.stats
        return stats.diskTotal ? Math.round(stats.diskUsed / 1073741824) + "/"
            + Math.round(stats.diskTotal / 1073741824) + " GiB" : "—"
    }
    radius: theme.topBar.radius
    color: theme.colors.topBarSurface
    border.width: theme.topBar.dividerWidth
    border.color: theme.colors.separator
    antialiasing: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 24
        ColumnLayout {
            Layout.preferredWidth: 640
            Layout.minimumWidth: 600
            Layout.maximumWidth: 640
            Layout.alignment: Qt.AlignTop
            spacing: 12
            MonoText { theme: root.theme; text: "SYSTEM"; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ResourceDetails {
                    theme: root.theme
                    stats: root.systemStats.stats
                    Layout.fillWidth: true
                    Layout.preferredWidth: 350
                }
                UsageGauge {
                    theme: root.theme
                    stats: root.systemStats.stats
                    Layout.preferredWidth: 300
                    Layout.minimumWidth: 240
                    Layout.preferredHeight: 190
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                MonoText { theme: root.theme; Layout.preferredWidth: 52; text: "SSD"; tone: root.theme.colors.textMuted; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: 2.5
                    color: root.theme.colors.frame
                    Rectangle {
                        width: parent.width * (root.systemStats.stats.diskTotal ? root.systemStats.stats.diskUsed / root.systemStats.stats.diskTotal : 0)
                        height: parent.height; radius: parent.radius; color: root.theme.colors.textSecondary
                    }
                }
                MonoText {
                    theme: root.theme
                    font.pixelSize: 12
                    text: root.systemStats.stats.diskTotal ? Math.round(root.systemStats.stats.diskUsed / root.systemStats.stats.diskTotal * 100) + "%" : "—"
                }
                MonoText { theme: root.theme; font.pixelSize: 12; tone: root.theme.colors.textSecondary; text: root.diskCapacity() }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                MonoText { theme: root.theme; Layout.preferredWidth: 52; text: "NET"; tone: root.theme.colors.textMuted; font.pixelSize: 12 }
                MonoText { theme: root.theme; Layout.fillWidth: true; font.pixelSize: 12; tone: root.theme.colors.textSecondary; elide: Text.ElideRight; text: !root.network.available ? "UNAVAILABLE" : root.network.offline ? "OFFLINE" : root.network.connectedDevice ? "CONNECTED · " + root.network.interfaceName : "DISCONNECTED" }
            }
        }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 280
            Layout.minimumWidth: 200
            Layout.alignment: Qt.AlignTop
        }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 400
            Layout.minimumWidth: 160
            Layout.maximumWidth: 420
            Layout.alignment: Qt.AlignTop
            spacing: 10
            MediaPanel { theme: root.theme; Layout.fillWidth: true }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.theme.colors.separator }
            ControlsPanel { theme: root.theme; audio: root.audio; Layout.fillWidth: true }
        }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
        ColumnLayout {
            Layout.preferredWidth: 180
            Layout.minimumWidth: 160
            Layout.maximumWidth: 200
            Layout.fillHeight: true
            spacing: 10
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: tray.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                TrayPanel { id: tray; theme: root.theme; width: parent.width }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.theme.colors.separator }
            PowerPanel { theme: root.theme; systemStatus: root.systemStatus; Layout.fillWidth: true }
        }
    }
}
