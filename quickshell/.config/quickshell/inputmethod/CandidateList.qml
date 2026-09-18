pragma ComponentBehavior: Bound
import QtQuick
import "../components"

Item {
    id: root
    required property var theme
    property var candidates: []
    property int selectedIndex: -1
    property bool horizontal: false
    property int maxVisibleRows: theme.inputMethod.maxVisibleRows
    readonly property real contentY: verticalList.contentY
    readonly property real contentHeight: verticalList.contentHeight
    property real maximumWidth: theme.inputMethod.maxWidth
    signal candidateSelected(int index)
    signal pageRequested(int direction)
    readonly property real preferredWidth: horizontal ? maximumWidth
        : Math.min(maximumWidth, Math.max(theme.inputMethod.minWidth, measuredWidth))
    readonly property real measuredWidth: {
        let widest = 0
        for (const candidate of candidates)
            widest = Math.max(widest, labelMetrics.advanceWidth(candidate.label || "")
                + valueMetrics.advanceWidth(candidate.text || "") + theme.inputMethod.padding * 2 + 12)
        return Math.ceil(widest)
    }
    property string pageKey: ""
    implicitWidth: preferredWidth
    implicitHeight: horizontal ? flow.implicitHeight
        : Math.min(candidates.length, maxVisibleRows) * theme.inputMethod.rowHeight
    clip: true

    function handleWheel(event) {
        if (Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)) {
            root.pageRequested(event.angleDelta.x < 0 ? 1 : -1)
        } else if (!root.horizontal) {
            const delta = event.pixelDelta.y !== 0 ? -event.pixelDelta.y
                : -event.angleDelta.y / 120 * root.theme.inputMethod.rowHeight
            if (delta !== 0) verticalList.scrollBy(delta)
        }
        event.accepted = true
    }

    StableListModel {
        id: entries
        items: root.candidates
    }
    SelectableList {
        id: verticalList
        anchors.fill: parent
        visible: !root.horizontal
        theme: root.theme
        rowHeight: root.theme.inputMethod.rowHeight
        maximumVisibleRows: root.maxVisibleRows
        model: root.horizontal ? [] : entries
        currentIndex: root.selectedIndex
        keyboardNavigation: false
        insetSelection: true
        onCurrentIndexChanged: Qt.callLater(() => verticalList.ensureVisible(root.selectedIndex))
        delegate: CandidateRow {
            required property var entry
            required property int index
            theme: root.theme
            candidate: entry
            selected: index === root.selectedIndex
            active: false
            width: verticalList.width
            onClicked: root.candidateSelected(index)
        }
    }
    SelectableFlow {
        id: flow
        width: root.width
        visible: root.horizontal
        theme: root.theme
        horizontal: true
        items: root.horizontal ? root.candidates : []
        currentIndex: root.selectedIndex
        rowHeight: root.theme.inputMethod.rowHeight
        delegate: CandidateRow {
            required property var entry
            required property int index
            theme: root.theme
            candidate: entry
            selected: index === root.selectedIndex
            active: false
            width: Math.min(implicitWidth, flow.width)
            onClicked: root.candidateSelected(index)
        }
    }
    FontMetrics {
        id: labelMetrics
        font.family: root.theme.typography.family
        font.pixelSize: root.theme.typography.detailSize
    }
    FontMetrics {
        id: valueMetrics
        font.family: root.theme.inputMethod.fontFamily
        font.pixelSize: root.theme.inputMethod.fontSize
    }
    onCandidatesChanged: {
        const nextKey = JSON.stringify(candidates)
        if (nextKey === pageKey) return
        pageKey = nextKey
        if (!horizontal) {
            verticalList.positionViewAtBeginning()
            Qt.callLater(() => verticalList.ensureVisible(root.selectedIndex))
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => root.handleWheel(event)
    }
}
