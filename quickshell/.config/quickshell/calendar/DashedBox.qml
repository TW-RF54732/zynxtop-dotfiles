import QtQuick

// Dashed rounded outline marking an event that does not exist yet.
Canvas {
    id: root
    property color stroke: "white"
    property real radius: 6
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onPaint: {
        const context = getContext("2d");
        context.reset();
        context.strokeStyle = root.stroke;
        context.lineWidth = 1.5;
        context.setLineDash([4, 3]);
        context.beginPath();
        context.roundedRect(0.75, 0.75, width - 1.5, height - 1.5, root.radius, root.radius);
        context.stroke();
    }
}
