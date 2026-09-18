pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../components"

GridLayout {
    id: root
    required property var theme
    required property var stats
    columns: 2
    columnSpacing: 18
    rowSpacing: 22
    function value(number, unit, digits) {
        return number === undefined || number === null ? "—" : Number(number).toFixed(digits) + unit
    }
    function capacity(used, total) {
        return total === undefined || total === null ? "—"
            : value(used / 1073741824, "", 1) + " / " + value(total / 1073741824, " GiB", 1)
    }
    readonly property var detailRows: [
        { label: "CPU", detail: value(stats.cpuGHz, " GHz", 2) + " · " + value(stats.cpuTemperature, "°C", 0) + " · " + value(stats.cpuThreads, " threads", 0) },
        { label: "RAM", detail: capacity(stats.ramUsed, stats.ramTotal) },
        { label: "SWAP", detail: capacity(stats.swapUsed, stats.swapTotal) },
        { label: "GPU", detail: value(stats.gpuTemperature, "°C", 0) + " · VRAM " + capacity(stats.gpuMemoryUsed, stats.gpuMemoryTotal) }
    ]
    Repeater {
        model: root.detailRows
        delegate: RowLayout {
            required property var modelData
            Layout.columnSpan: 2
            Layout.fillWidth: true
            spacing: 18
            MonoText { theme: root.theme; Layout.preferredWidth: 52; text: parent.modelData.label; font.pixelSize: 12; tone: root.theme.colors.textMuted }
            MonoText { theme: root.theme; Layout.fillWidth: true; text: parent.modelData.detail; font.pixelSize: 12; tone: root.theme.colors.textSecondary; elide: Text.ElideRight }
        }
    }
}
