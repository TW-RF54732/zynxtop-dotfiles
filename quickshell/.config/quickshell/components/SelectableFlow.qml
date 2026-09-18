pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    required property var theme
    required property Component delegate
    property var items: []
    property int currentIndex: -1
    property bool horizontal: false
    property int rowHeight: theme.geometry.controlSize
    property real minimumWidth: 0
    property real maximumWidth: 480
    property bool insetSelection: !horizontal
    property real selectionInset: insetSelection ? theme.geometry.frameWidth : 0
    property var isSelectable: index => true
    property real measuredWidth: minimumWidth
    property int layoutRevision: 0
    property bool allowMotion: false
    readonly property int count: entries.count
    readonly property real preferredWidth: horizontal ? maximumWidth
        : Math.min(maximumWidth, Math.max(minimumWidth, measuredWidth))
    readonly property var selectedRow: {
        layoutRevision
        return currentIndex >= 0 && currentIndex < rows.count ? rows.itemAt(currentIndex) : null
    }
    readonly property real selectionY: selection.y
    signal selectionRequested(int index)
    implicitWidth: preferredWidth
    implicitHeight: horizontal ? flow.implicitHeight : count * rowHeight

    function itemAt(index) { return rows.itemAt(index) }
    function measureRows() {
        let measured = minimumWidth
        for (let i = 0; i < rows.count; ++i) {
            const row = rows.itemAt(i)
            if (row) measured = Math.max(measured, row.implicitWidth)
        }
        measuredWidth = measured
    }
    function scheduleMeasurement() { Qt.callLater(root.measureRows) }
    function finishModelUpdate() {
        measureRows()
        allowMotion = true
    }
    function moveSelection(delta) {
        if (count === 0 || delta === 0) return
        let next = currentIndex < 0 ? (delta > 0 ? 0 : count - 1) : currentIndex + delta
        while (next >= 0 && next < count && !isSelectable(next)) next += delta > 0 ? 1 : -1
        if (next >= 0 && next < count) selectionRequested(next)
    }
    onMinimumWidthChanged: scheduleMeasurement()

    StableListModel {
        id: entries
        items: root.items
        onRefreshed: {
            root.allowMotion = false
            Qt.callLater(root.finishModelUpdate)
        }
    }
    SelectionHighlight {
        id: selection
        theme: root.theme
        inset: root.insetSelection
        animate: root.allowMotion
        targetX: root.selectedRow ? root.selectedRow.x - root.selectionInset : 0
        targetY: root.selectedRow ? root.selectedRow.y - (inset ? root.theme.geometry.insetCurveRadius : 0) : 0
        targetWidth: root.selectedRow ? root.selectedRow.width + root.selectionInset * 2 : 0
        targetHeight: root.selectedRow ? root.selectedRow.height + (inset ? root.theme.geometry.insetCurveRadius * 2 : 0) : 0
        visible: root.selectedRow !== null
    }
    Flow {
        id: flow
        width: root.width
        spacing: 0
        onPositioningComplete: root.layoutRevision++
        Repeater {
            id: rows
            model: entries
            delegate: root.delegate
            onItemAdded: (index, item) => {
                root.layoutRevision++
                item.implicitWidthChanged.connect(root.scheduleMeasurement)
                root.scheduleMeasurement()
            }
            onItemRemoved: {
                root.layoutRevision++
                root.scheduleMeasurement()
            }
        }
    }
}
