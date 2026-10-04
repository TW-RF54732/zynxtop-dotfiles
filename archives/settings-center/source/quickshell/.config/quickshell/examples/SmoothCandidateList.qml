pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "../inputmethod"

SelectableFlow {
    id: root
    property var candidates: []
    property int selectedIndex: -1
    items: candidates
    currentIndex: selectedIndex
    rowHeight: theme.inputMethod.rowHeight
    minimumWidth: theme.inputMethod.minWidth
    maximumWidth: theme.inputMethod.maxWidth
    signal candidateSelected(int index)
    signal pageRequested(int direction)

    delegate: CandidateRow {
        required property var entry
        required property int index
        theme: root.theme
        candidate: entry
        selected: index === root.selectedIndex
        active: false
        width: root.horizontal ? Math.min(implicitWidth, root.width) : root.width
        onClicked: root.candidateSelected(index)
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.angleDelta.y !== 0) root.pageRequested(event.angleDelta.y < 0 ? 1 : -1)
            event.accepted = true
        }
    }
}
