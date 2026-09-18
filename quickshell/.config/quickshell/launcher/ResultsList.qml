pragma ComponentBehavior: Bound
import QtQuick
import "../components"

Item {
    id: root
    required property var theme
    required property var results
    required property int selectedIndex
    readonly property real contentY: resultList.contentY
    readonly property real contentHeight: resultList.contentHeight
    property real edgeBounceTarget: 0
    property real edgeBounceReturn: 0
    signal selectionRequested(int index)
    signal activationRequested()
    implicitHeight: results.length === 0 ? theme.launcher.emptyResultHeight
        : Math.min(theme.launcher.maxVisibleResults, results.length) * theme.launcher.resultHeight

    function positionViewAtBeginning() { resultList.positionViewAtBeginning() }
    function moveSelection(delta) {
        if (root.results.length === 0) return
        const nextIndex = root.selectedIndex + delta
        if (nextIndex < 0 || nextIndex >= root.results.length) {
            bounceAtEdge(delta)
            return
        }

        const rowHeight = root.theme.launcher.resultHeight
        const currentRowTop = root.selectedIndex * rowHeight - resultList.contentY
        const leavingVisibleEdge = delta > 0
            ? currentRowTop >= resultList.height - rowHeight
            : currentRowTop <= 0
        root.selectionRequested(nextIndex)

        if (leavingVisibleEdge) {
            const centered = nextIndex * rowHeight
                - (resultList.height - rowHeight) / 2
            const maximum = Math.max(0, resultList.contentHeight - resultList.height)
            animateListTo(Math.max(0, Math.min(maximum, centered)))
        }
    }

    function animateListTo(position) {
        edgeBounceAnimation.stop()
        listScrollAnimation.stop()
        listScrollAnimation.to = position
        listScrollAnimation.restart()
    }

    function bounceAtEdge(direction) {
        listScrollAnimation.stop()
        edgeBounceAnimation.stop()
        const maximum = Math.max(0, resultList.contentHeight - resultList.height)
        edgeBounceReturn = direction > 0 ? maximum : 0
        edgeBounceTarget = edgeBounceReturn
            + (direction > 0 ? root.theme.motion.edgeBounceDistance : -root.theme.motion.edgeBounceDistance)
        edgeBounceAnimation.restart()
    }

    NumberAnimation {
        id: listScrollAnimation
        target: resultList
        property: "contentY"
        duration: root.theme.motion.listScrollDuration
        easing.type: Easing.Linear
    }

    SequentialAnimation {
        id: edgeBounceAnimation
        NumberAnimation {
            target: resultList
            property: "contentY"
            to: root.edgeBounceTarget
            duration: root.theme.motion.edgeBounceDuration
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: resultList
            property: "contentY"
            to: root.edgeBounceReturn
            duration: root.theme.motion.edgeBounceDuration
            easing.type: Easing.InQuad
        }
    }

    InsetHighlight {
        theme: root.theme
        x: 0
        y: -resultList.contentY - root.theme.geometry.insetCurveRadius
        selectionOffset: root.selectedIndex * root.theme.launcher.resultHeight
        width: root.width
        height: root.theme.launcher.resultHeight + root.theme.geometry.insetCurveRadius * 2
        visible: root.results.length > 0
        z: 1
    }
    ListView {
        id: resultList
        anchors.fill: parent
        clip: true
        z: 2
        model: root.results
        currentIndex: root.selectedIndex
        boundsBehavior: Flickable.StopAtBounds

        delegate: ResultRow {
            required property var modelData
            required property int index
            width: resultList.width
            theme: root.theme
            app: modelData.app
            selected: index === root.selectedIndex
            onHovered: root.selectionRequested(index)
            onActivated: root.activationRequested()
        }
        MonoText {
            theme: root.theme
            anchors.centerIn: parent
            visible: root.results.length === 0
            text: "no matching application"
            tone: root.theme.colors.textMuted
            font.pixelSize: root.theme.typography.emptySize
        }
    }
}
