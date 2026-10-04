import QtQuick

ListView {
    id: root
    required property var theme
    required property real rowHeight
    property real bounceTarget: 0
    property real bounceReturn: 0
    property real bounceOffset: 0
    property bool followSelection: true
    function resetScroll() {
        scroll.stop(); bounce.stop(); bounceOffset = 0
        positionViewAtBeginning()
    }
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    highlightFollowsCurrentItem: false

    function scrollTo(value) {
        bounce.stop()
        bounceOffset = 0
        const next = Math.max(0, Math.min(Math.max(0, contentHeight - height), value))
        if (scroll.running && Math.abs(scroll.to - next) < 0.5) return
        scroll.stop()
        scroll.to = next
        scroll.restart()
    }
    function scrollBy(delta) {
        const target = (scroll.running ? scroll.to : contentY) + delta
        if (target < 0 || target > Math.max(0, contentHeight - height)) bounceAtEdge(delta)
        else scrollTo(target)
    }
    function ensureVisible(index) {
        forceLayout()
        if (index < 0 || index >= count) return
        const top = index * rowHeight
        if (top < contentY || top + rowHeight > contentY + height)
            scrollTo(top - (height - rowHeight) / 2)
    }
    function bounceAtEdge(direction) {
        scroll.stop()
        bounce.stop()
        bounceReturn = direction > 0 ? Math.max(0, contentHeight - height) : 0
        bounceTarget = (direction > 0 ? -1 : 1) * theme.motion.edgeBounceDistance
        bounce.restart()
    }
    onCurrentIndexChanged: if (followSelection) Qt.callLater(() => root.ensureVisible(root.currentIndex))
    NumberAnimation {
        id: scroll
        target: root; property: "contentY"
        duration: root.theme.motion.listScrollDuration
        easing.type: Easing.OutCubic
    }
    SequentialAnimation {
        id: bounce
        NumberAnimation {
            target: root; property: "bounceOffset"; to: root.bounceTarget
            duration: root.theme.motion.edgeBounceDuration; easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root; property: "bounceOffset"; to: 0
            duration: root.theme.motion.edgeBounceDuration; easing.type: Easing.InQuad
        }
    }
}
