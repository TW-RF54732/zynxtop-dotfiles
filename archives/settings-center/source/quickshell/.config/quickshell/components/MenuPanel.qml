pragma ComponentBehavior: Bound
import QtQuick

PanelTransition {
    id: root
    property var items: []
    property int currentIndex: 0
    property int maximumVisibleRows: 7
    property int rowHeight: theme.geometry.controlSize
    signal triggered(int index, var entry)
    signal dismissRequested()
    focus: shown
    implicitWidth: 280
    implicitHeight: list.implicitHeight + theme.geometry.frameWidth * 2

    StableListModel { id: entries; items: root.items }
    GlassFrame {
        theme: root.theme
        width: root.width
        height: root.height
        SelectableList {
            id: list
            theme: root.theme
            x: root.theme.geometry.frameWidth
            y: root.theme.geometry.frameWidth
            width: parent.width - root.theme.geometry.frameWidth * 2
            model: entries
            currentIndex: root.currentIndex
            rowHeight: root.rowHeight
            maximumVisibleRows: root.maximumVisibleRows
            insetSelection: true
            selectionInset: root.theme.geometry.frameWidth
            hoverSelection: true
            isSelectable: index => root.items[index].enabled !== false
            onSelectionRequested: index => root.currentIndex = index
            onActivationRequested: root.activateCurrent()
            delegate: MenuRow {
                required property int index
                theme: root.theme
                width: list.width
                height: list.rowHeight
                selected: index === root.currentIndex
                onClicked: {
                    root.currentIndex = index
                    root.activateCurrent()
                }
            }
        }
    }
    onItemsChanged: normalizeSelection()
    function normalizeSelection() {
        if (currentIndex >= 0 && currentIndex < items.length && items[currentIndex].enabled !== false) return
        currentIndex = -1
        for (let i = 0; i < items.length; ++i) {
            if (items[i].enabled !== false) { currentIndex = i; break }
        }
    }
    function activateCurrent() {
        if (currentIndex >= 0 && currentIndex < items.length && items[currentIndex].enabled !== false)
            triggered(currentIndex, items[currentIndex])
    }
    function moveSelection(delta) { list.moveSelection(delta) }
    Keys.onDownPressed: moveSelection(1)
    Keys.onUpPressed: moveSelection(-1)
    Keys.onReturnPressed: activateCurrent()
    Keys.onEscapePressed: dismissRequested()
}
