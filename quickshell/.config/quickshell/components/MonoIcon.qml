import QtQuick

Item {
    id: root

    required property string name
    property var theme: null
    property color color: theme ? theme.colors.textSecondary : "white"
    property real lineWidth: theme ? theme.geometry.iconStrokeWidth : 1.7

    implicitWidth: theme ? theme.geometry.iconSize : 18
    implicitHeight: implicitWidth

    onNameChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onLineWidthChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function begin(context) {
            context.reset()
            context.clearRect(0, 0, width, height)
            context.strokeStyle = root.color
            context.fillStyle = root.color
            context.lineWidth = root.lineWidth
            context.lineCap = "round"
            context.lineJoin = "round"
        }

        function arc(context, radius, startAngle, endAngle) {
            context.beginPath()
            context.arc(width / 2, height * 0.72, radius, startAngle, endAngle)
            context.stroke()
        }

        onPaint: {
            const context = getContext("2d")
            begin(context)

            if (root.name === "bell") {
                context.beginPath()
                context.moveTo(width * 0.22, height * 0.72)
                context.quadraticCurveTo(width * 0.32, height * 0.60, width * 0.32, height * 0.38)
                context.arc(width * 0.50, height * 0.38, width * 0.18, Math.PI, 0)
                context.quadraticCurveTo(width * 0.68, height * 0.60, width * 0.78, height * 0.72)
                context.closePath()
                context.stroke()
                context.beginPath()
                context.arc(width * 0.50, height * 0.78, width * 0.08, 0, Math.PI)
                context.stroke()
            } else if (root.name === "offline") {
                arc(context, width * 0.42, Math.PI * 1.18, Math.PI * 1.82)
                arc(context, width * 0.27, Math.PI * 1.18, Math.PI * 1.82)
                context.beginPath()
                context.arc(width / 2, height * 0.72, root.lineWidth, 0, Math.PI * 2)
                context.fill()
                context.beginPath()
                context.moveTo(width * 0.16, height * 0.16)
                context.lineTo(width * 0.84, height * 0.84)
                context.stroke()
            } else if (root.name === "volume") {
                context.beginPath()
                context.moveTo(width * 0.12, height * 0.40)
                context.lineTo(width * 0.34, height * 0.40)
                context.lineTo(width * 0.58, height * 0.20)
                context.lineTo(width * 0.58, height * 0.80)
                context.lineTo(width * 0.34, height * 0.60)
                context.lineTo(width * 0.12, height * 0.60)
                context.closePath()
                context.stroke()
                context.beginPath()
                context.arc(width * 0.57, height * 0.50, width * 0.22,
                    -Math.PI * 0.38, Math.PI * 0.38)
                context.stroke()
            } else if (root.name === "muted") {
                context.beginPath()
                context.moveTo(width * 0.12, height * 0.40)
                context.lineTo(width * 0.34, height * 0.40)
                context.lineTo(width * 0.58, height * 0.20)
                context.lineTo(width * 0.58, height * 0.80)
                context.lineTo(width * 0.34, height * 0.60)
                context.lineTo(width * 0.12, height * 0.60)
                context.closePath()
                context.stroke()
                context.beginPath()
                context.moveTo(width * 0.70, height * 0.38)
                context.lineTo(width * 0.90, height * 0.62)
                context.moveTo(width * 0.90, height * 0.38)
                context.lineTo(width * 0.70, height * 0.62)
                context.stroke()
            } else if (root.name === "star") {
                const outerRadius = Math.min(width, height) * 0.43
                const innerRadius = outerRadius * 0.45
                context.beginPath()
                for (let i = 0; i < 10; ++i) {
                    const angle = -Math.PI / 2 + i * Math.PI / 5
                    const radius = i % 2 === 0 ? outerRadius : innerRadius
                    const x = width / 2 + Math.cos(angle) * radius
                    const y = height / 2 + Math.sin(angle) * radius
                    if (i === 0) context.moveTo(x, y)
                    else context.lineTo(x, y)
                }
                context.closePath()
                context.stroke()
            } else if (root.name === "dashboard") {
                const size = width * 0.27
                const gap = width * 0.15
                const left = (width - size * 2 - gap) / 2
                const top = (height - size * 2 - gap) / 2
                context.strokeRect(left, top, size, size)
                context.strokeRect(left + size + gap, top, size, size)
                context.strokeRect(left, top + size + gap, size, size)
                context.strokeRect(left + size + gap, top + size + gap, size, size)
            } else if (root.name === "lock") {
                context.strokeRect(width * 0.25, height * 0.45, width * 0.5, height * 0.4)
                context.beginPath()
                context.moveTo(width * 0.35, height * 0.45)
                context.lineTo(width * 0.35, height * 0.3)
                context.arc(width * 0.5, height * 0.3, width * 0.15, Math.PI, 0)
                context.lineTo(width * 0.65, height * 0.45)
                context.stroke()
            } else if (root.name === "power") {
                context.beginPath()
                context.arc(width * 0.5, height * 0.52, width * 0.34, -Math.PI * 0.3, Math.PI * 1.3)
                context.stroke()
                context.beginPath()
                context.moveTo(width * 0.5, height * 0.12)
                context.lineTo(width * 0.5, height * 0.5)
                context.stroke()
            } else if (root.name === "reboot") {
                context.beginPath()
                context.arc(width * 0.5, height * 0.5, width * 0.32, -Math.PI * 0.25, Math.PI * 1.5)
                context.stroke()
                context.beginPath()
                context.moveTo(width * 0.34, height * 0.08)
                context.lineTo(width * 0.5, height * 0.18)
                context.lineTo(width * 0.36, height * 0.31)
                context.stroke()
            } else if (root.name === "hibernate") {
                for (let i = 0; i < 3; ++i) {
                    const angle = i * Math.PI / 3
                    const dx = Math.cos(angle) * width * 0.34
                    const dy = Math.sin(angle) * height * 0.34
                    context.beginPath()
                    context.moveTo(width * 0.5 - dx, height * 0.5 - dy)
                    context.lineTo(width * 0.5 + dx, height * 0.5 + dy)
                    context.stroke()
                }
            } else if (root.name === "sun") {
                const centerX = width / 2
                const centerY = height / 2
                const radius = Math.min(width, height) * 0.2
                const rayStart = Math.min(width, height) * 0.34
                const rayEnd = Math.min(width, height) * 0.46

                context.beginPath()
                context.arc(centerX, centerY, radius, 0, Math.PI * 2)
                context.stroke()
                for (let i = 0; i < 8; ++i) {
                    const angle = i * Math.PI / 4
                    context.beginPath()
                    context.moveTo(centerX + Math.cos(angle) * rayStart,
                                   centerY + Math.sin(angle) * rayStart)
                    context.lineTo(centerX + Math.cos(angle) * rayEnd,
                                   centerY + Math.sin(angle) * rayEnd)
                    context.stroke()
                }
            } else if (root.name === "moon") {
                const cx = width * 0.50
                const cy = height * 0.50
                const r = Math.min(width, height) * 0.36

                context.beginPath()

                // 外側圓弧
                context.arc(
                    cx,
                    cy,
                    r,
                    Math.PI * 0.28,
                    Math.PI * 1.72,
                    false
                )

                // 內側圓弧
                context.arc(
                    cx + r * 0.42,
                    cy,
                    r * 0.78,
                    Math.PI * 1.63,
                    Math.PI * 0.37,
                    true
                )

                context.closePath()
                context.fill()
            }
        }
    }
}
