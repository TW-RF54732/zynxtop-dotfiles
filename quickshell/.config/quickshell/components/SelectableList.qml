pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    required property var theme
    required property var model
    required property Component delegate
    property int currentIndex: -1
    property int rowHeight: theme.geometry.controlSize
    property int maximumVisibleRows: 7
    property int emptyHeight: 0
    property bool insetSelection: false
    property real selectionInset: 0
    property real selectionLeftEdge: theme.geometry.frameWidth
    property bool hoverSelection: false
    property bool keyboardNavigation: true
    property var isSelectable: index => true
    readonly property int count: viewport.count
    readonly property real contentY: viewport.contentY
    readonly property real contentHeight: viewport.contentHeight
    readonly property real maximumScroll: Math.max(0, contentHeight - height)
    readonly property real selectionY: highlight.y
    readonly property real bounceOffset: viewport.bounceOffset
    property real bounceTarget: 0
    property bool keyboardSelection: false
    property real pointerX: -1
    property real pointerY: -1
    signal selectionRequested(int index)
    signal activationRequested()
    implicitHeight: count === 0 ? emptyHeight : Math.min(maximumVisibleRows, count) * rowHeight

    function positionViewAtBeginning() { viewport.resetScroll() }
    function scrollTo(position) { viewport.scrollTo(position) }
    function scrollBy(delta) { viewport.scrollBy(delta) }
    function ensureVisible(index) { viewport.ensureVisible(index) }
    function bounceAtEdge(direction) { viewport.bounceAtEdge(direction) }
    function moveSelection(delta) {
        if (count === 0 || delta === 0) return
        keyboardSelection = true
        let next = currentIndex < 0 ? (delta > 0 ? 0 : count - 1) : currentIndex + delta
        while (next >= 0 && next < count && !isSelectable(next)) next += delta > 0 ? 1 : -1
        if (next < 0 || next >= count) {
            bounceAtEdge(delta)
            return
        }
        const top = currentIndex * rowHeight - viewport.contentY
        const leavingEdge = delta > 0 ? top >= height - rowHeight - 0.5 : top <= 0.5
        selectionRequested(next)
        if (leavingEdge) scrollTo(next * rowHeight - (height - rowHeight) / 2)
    }
    function selectAt(y) {
        const index = Math.floor((y - bounceOffset + viewport.contentY) / rowHeight)
        if (index >= 0 && index < count && isSelectable(index) && index !== currentIndex)
            selectionRequested(index)
    }

    Keys.onDownPressed: event => {
        if (keyboardNavigation) moveSelection(1)
        else event.accepted = false
    }
    Keys.onUpPressed: event => {
        if (keyboardNavigation) moveSelection(-1)
        else event.accepted = false
    }
    Keys.onReturnPressed: event => {
        if (keyboardNavigation) activationRequested()
        else event.accepted = false
    }

    Item {
        anchors.fill: parent
        transform: Translate { y: root.bounceOffset }
        SelectionHighlight {
            id: highlight
            theme: root.theme
            inset: root.insetSelection
            leftEdge: root.selectionLeftEdge
            targetX: -root.selectionInset
            // Scroll is already animated: animate only the selection offset below.
            targetY: root.currentIndex * root.rowHeight
                - (root.insetSelection ? root.theme.geometry.insetCurveRadius : 0)
            targetWidth: root.width + root.selectionInset * 2
            targetHeight: root.rowHeight + (root.insetSelection ? root.theme.geometry.insetCurveRadius * 2 : 0)
            transform: Translate { y: -viewport.contentY }
            visible: root.currentIndex >= 0 && root.currentIndex < root.count
        }
        AnimatedListView {
            theme: root.theme
            rowHeight: root.rowHeight
            followSelection: false
            id: viewport
            anchors.fill: parent
            z: 1
            clip: true
            model: root.model
            delegate: root.delegate
            // Selection belongs to the caller; avoid a second automatic scroll.
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            onCountChanged: Qt.callLater(() => {
                if (viewport.contentY > root.maximumScroll) viewport.contentY = root.maximumScroll
            })
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: root.hoverSelection
        onEntered: {
            if (!root.keyboardSelection) root.selectAt(mouseY)
            root.pointerX = mouseX
            root.pointerY = mouseY
        }
        onPositionChanged: mouse => {
            if (!root.hoverSelection) return
            if (Math.abs(mouse.x - root.pointerX) < 0.5 && Math.abs(mouse.y - root.pointerY) < 0.5) return
            root.pointerX = mouse.x
            root.pointerY = mouse.y
            root.keyboardSelection = false
            root.selectAt(mouse.y)
        }
        onWheel: event => event.accepted = false
    }
}
