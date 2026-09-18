pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    required property var theme
    property var candidates: []
    property int selectedIndex: -1
    property bool horizontal: false
    property real maximumWidth: theme.inputMethod.maxWidth
    property int pageNumber: 1
    property int pageDirection: 0
    property int pageRevision: 0
    property int displayedRevision: 0
    property bool firstActive: true
    property string contentKey: ""
    property int displayedPage: 1
    property int direction: 1
    property real progress: 1
    property real retainedHeight: 0
    readonly property var activeList: firstActive ? first : second
    readonly property real preferredWidth: activeList.preferredWidth
    readonly property bool animating: slide.running
    signal candidateSelected(int index)
    signal pageRequested(int direction)
    implicitWidth: preferredWidth
    implicitHeight: Math.max(retainedHeight, activeList.implicitHeight)
    clip: true

    function synchronize() {
        const key = JSON.stringify(candidates)
        if (key === contentKey) { activeList.selectedIndex = selectedIndex; return }
        const animate = contentKey !== "" && activeList.candidates.length > 0
            && candidates.length > 0 && pageDirection !== 0
            && (pageRevision !== displayedRevision || pageNumber !== displayedPage)
        retainedHeight = animate ? Math.max(retainedHeight, activeList.implicitHeight) : 0
        slide.stop()
        progress = 1
        if (animate) {
            direction = pageDirection
            firstActive = !firstActive
        }
        activeList.candidates = candidates
        activeList.selectedIndex = selectedIndex
        contentKey = key
        displayedPage = pageNumber
        displayedRevision = pageRevision
        if (animate) { progress = 0; slide.restart() }
    }
    onCandidatesChanged: Qt.callLater(root.synchronize)
    onPageRevisionChanged: Qt.callLater(root.synchronize)
    onPageNumberChanged: Qt.callLater(root.synchronize)
    onSelectedIndexChanged: activeList.selectedIndex = selectedIndex
    Component.onCompleted: Qt.callLater(root.synchronize)
    // The frame remains fixed while a shorter page leaves an empty surface below.
    Rectangle {
        x: root.theme.geometry.frameWidth
        width: Math.max(0, root.width - root.theme.geometry.frameWidth * 2)
        height: root.height
        color: root.theme.colors.surface
    }
    CandidateList {
        id: first
        theme: root.theme
        width: root.width
        height: root.height
        maximumWidth: root.maximumWidth
        horizontal: root.horizontal
        visible: root.firstActive || root.animating
        enabled: root.firstActive && !root.animating
        x: root.firstActive ? root.direction * root.width * (1 - root.progress)
            : -root.direction * root.width * root.progress
        onCandidateSelected: index => root.candidateSelected(index)
        onPageRequested: direction => root.pageRequested(direction)
    }
    CandidateList {
        id: second
        theme: root.theme
        width: root.width
        height: root.height
        maximumWidth: root.maximumWidth
        horizontal: root.horizontal
        visible: !root.firstActive || root.animating
        enabled: !root.firstActive && !root.animating
        x: !root.firstActive ? root.direction * root.width * (1 - root.progress)
            : -root.direction * root.width * root.progress
        onCandidateSelected: index => root.candidateSelected(index)
        onPageRequested: direction => root.pageRequested(direction)
    }
    NumberAnimation {
        id: slide
        target: root
        property: "progress"
        to: 1
        duration: root.theme.motion.listScrollDuration
        easing.type: Easing.OutCubic
    }
}
