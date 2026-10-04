pragma ComponentBehavior: Bound

import QtQuick
import "../components"

Item {
    id: root
    required property var theme
    required property var stats
    readonly property var values: [stats.cpu, stats.ram, stats.gpu]
    readonly property var tones: [theme.colors.textPrimary, theme.colors.textSecondary, theme.colors.textMuted]
    function percentage(value) {
        return value === undefined || value === null ? "—" : Math.round(value) + "%"
    }
    readonly property real arcBaseline: height - labels.implicitHeight - 20
    implicitWidth: 330
    implicitHeight: 190

    Repeater {
        model: 3
        delegate: Canvas {
            id: ring
            required property int index
            anchors.fill: parent
            property real progress: root.values[index] === undefined || root.values[index] === null
                ? 0 : Math.max(0, Math.min(100, root.values[index])) / 100
            Behavior on progress { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            onProgressChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: root
                function onArcBaselineChanged() { ring.requestPaint() }
            }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const radius = Math.min(width / 2 - 12, root.arcBaseline - 10) - index * 23
                if (radius <= 0) return
                ctx.lineWidth = 11
                ctx.lineCap = "round"
                ctx.strokeStyle = root.theme.colors.frame
                ctx.beginPath()
                ctx.arc(width / 2, root.arcBaseline, radius, Math.PI, Math.PI * 2)
                ctx.stroke()
                if (progress > 0) {
                    ctx.strokeStyle = root.tones[index]
                    ctx.beginPath()
                    ctx.arc(width / 2, root.arcBaseline, radius, Math.PI, Math.PI + Math.PI * progress)
                    ctx.stroke()
                }
            }
        }
    }
    Row {
        id: labels
        anchors.bottom: parent.bottom
        width: parent.width
        Repeater {
            model: ["CPU", "RAM", "GPU"]
            delegate: Column {
                required property int index
                required property string modelData
                width: root.width / 3
                spacing: 3
                MonoText { theme: root.theme; anchors.horizontalCenter: parent.horizontalCenter; text: parent.modelData; tone: root.tones[parent.index]; font.pixelSize: 12 }
                MonoText { theme: root.theme; anchors.horizontalCenter: parent.horizontalCenter; text: root.percentage(root.values[parent.index]); font.pixelSize: 19 }
            }
        }
    }
}
