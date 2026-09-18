pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"

ColumnLayout {
    id: root
    required property var theme
    required property SystemStatusService systemStatus
    readonly property var status: systemStatus.status
    spacing: 10
    function uptimeLabel(seconds) {
        if (seconds === undefined) return "—"
        return Math.floor(seconds / 86400) + "d " + Math.floor(seconds % 86400 / 3600) + "h " + Math.floor(seconds % 3600 / 60) + "m"
    }
    MonoText { theme: root.theme; text: "OS"; font.pixelSize: 12; tone: root.theme.colors.textSecondary }
    Repeater {
        model: [root.status.osVersion || "—", "CORE · " + (root.status.kernel || "—"),
            "RUNNING · " + root.uptimeLabel(root.status.uptime), "UPDATE · " + (root.status.updates || "LOADING"),
            "REBOOT · " + (root.status.reboot || "LOADING")]
        delegate: MonoText {
            required property string modelData
            theme: root.theme; text: modelData; font.pixelSize: 12
            Layout.fillWidth: true; wrapMode: Text.Wrap
        }
    }
}
