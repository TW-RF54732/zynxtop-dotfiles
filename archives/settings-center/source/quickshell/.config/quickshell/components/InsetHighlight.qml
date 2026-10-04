import QtQuick

Item {
    id: root
    required property var theme
    property color fillColor: theme.colors.frame
    property int moveDuration: theme.motion.selectionDuration
    property real selectionOffset: 0
    property real leftEdge: theme.geometry.frameWidth
    onLeftEdgeChanged: canvas.requestPaint()

    onFillColorChanged: canvas.requestPaint()

    Behavior on selectionOffset {
        NumberAnimation {
            duration: root.moveDuration
            easing.type: Easing.Linear
        }
    }

    transform: Translate { y: root.selectionOffset }

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const context = getContext("2d")
            const edge = root.leftEdge
            const rightEdge = root.theme.geometry.frameWidth
            const radius = root.theme.geometry.insetCurveRadius
            context.clearRect(0, 0, width, height)
            context.fillStyle = root.fillColor
            context.beginPath()
            context.moveTo(0, 0)
            context.lineTo(edge, 0)
            context.quadraticCurveTo(edge, radius, edge + radius, radius)
            context.lineTo(width - rightEdge - radius, radius)
            context.quadraticCurveTo(width - rightEdge, radius, width - rightEdge, 0)
            context.lineTo(width, 0)
            context.lineTo(width, height)
            context.lineTo(width - rightEdge, height)
            context.quadraticCurveTo(width - rightEdge, height - radius,
                                     width - rightEdge - radius, height - radius)
            context.lineTo(edge + radius, height - radius)
            context.quadraticCurveTo(edge, height - radius, edge, height)
            context.lineTo(0, height)
            context.closePath()
            context.fill()
        }
    }
}
