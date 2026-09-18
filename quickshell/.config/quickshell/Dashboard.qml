import QtQuick
import QtQuick.Layouts
import "components"
import "dashboard"
import "services"

GlassFrame {
    id: root
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
        anchors.margins: 24
        spacing: 28
        ColumnLayout {
            Layout.preferredWidth: 660
            Layout.minimumWidth: 600
            Layout.maximumWidth: 660
            Layout.fillHeight: true
            spacing: 14
            MonoText { theme: root.theme; text: "SYSTEM"; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                spacing: 24
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
            Item { Layout.fillHeight: true }
        }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
        MediaPanel { theme: root.theme; Layout.fillWidth: true; Layout.preferredWidth: 400; Layout.minimumWidth: 160 }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
        ControlsPanel { theme: root.theme; audio: root.audio; network: root.network; Layout.preferredWidth: 260; Layout.maximumWidth: 300; Layout.fillWidth: true }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
        TrayPanel { theme: root.theme; Layout.preferredWidth: 120; Layout.maximumWidth: 120; Layout.fillHeight: true }
    }
}
