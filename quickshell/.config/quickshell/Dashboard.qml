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
    // Which flyout the host currently shows beside the Dashboard: "", "tray" or "power".
    property string flyout: ""
    signal flyoutRequested(string name)
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
                    network: root.network
                    Layout.fillWidth: true
                    Layout.preferredWidth: 350
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 18
                }
                UsageGauge {
                    theme: root.theme
                    stats: root.systemStats.stats
                    Layout.preferredWidth: 300
                    Layout.minimumWidth: 240
                    Layout.preferredHeight: 178
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
        }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 280
            Layout.minimumWidth: 200
            Layout.fillHeight: true
            // Centered in the blank column so it follows the squeeze when a flyout opens.
            DashboardOrnament { anchors.fill: parent; theme: root.theme }
        }
        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
        // Mirrors the SYSTEM column's width so the blank column between them stays centered.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 640
            Layout.minimumWidth: 600
            Layout.maximumWidth: 640
            Layout.fillHeight: true
            spacing: 24
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 10
                MediaPanel { theme: root.theme; Layout.fillWidth: true }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.theme.colors.separator }
                ControlsPanel { theme: root.theme; audio: root.audio; Layout.fillWidth: true }
            }
            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: root.theme.colors.separator }
            ColumnLayout {
                Layout.preferredWidth: 40
                Layout.fillHeight: true
                spacing: 8
                IconButton {
                    theme: root.theme
                    name: "tray"
                    hoverEnabled: true
                    active: root.flyout === "tray"
                    implicitWidth: 40; implicitHeight: 40; iconSize: 18
                    Accessible.name: "Tray"
                    Accessible.role: Accessible.Button
                    onClicked: root.flyoutRequested("tray")
                }
                IconButton {
                    theme: root.theme
                    name: "power"
                    hoverEnabled: true
                    active: root.flyout === "power"
                    implicitWidth: 40; implicitHeight: 40; iconSize: 18
                    Accessible.name: "Power"
                    Accessible.role: Accessible.Button
                    onClicked: root.flyoutRequested("power")
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
