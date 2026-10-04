pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "components"
import "examples"

ShellRoot {
    id: testRoot
    property int failures: 0
    property int widthChanges: 0
    property int listIndex: 0
    property int triggeredIndex: -1
    property var initialCandidate: null
    property real initialWidth: 0
    property real beforeRetarget: 0
    property var candidates: [
        { label: "1", text: "這是一段足夠長的候選字測試文字", selectable: true },
        { label: "2", text: "中文", selectable: true },
        { label: "3", text: "中午", selectable: true }
    ]
    property var records: [
        { text: "One" }, { text: "Two" }, { text: "Three" }, { text: "Four" },
        { text: "Five" }, { text: "Six" }, { text: "Seven" }, { text: "Eight" },
        { text: "Nine" }, { text: "Ten" }
    ]
    Style { id: testTheme }
    StableListModel { id: entries; items: testRoot.records }
    Item {
        width: 1000
        height: 1000
        SmoothCandidateList {
            id: candidateList
            width: 240
            theme: testTheme
            candidates: testRoot.candidates
            selectedIndex: 0
            onMeasuredWidthChanged: testRoot.widthChanges++
        }
        SelectableList {
            id: list
            theme: testTheme
            width: 280
            model: entries
            maximumVisibleRows: 5
            currentIndex: testRoot.listIndex
            onSelectionRequested: index => testRoot.listIndex = index
            delegate: MenuRow {
                required property int index
                theme: testTheme
                width: list.width
                height: list.rowHeight
                selected: index === testRoot.listIndex
            }
        }
        MenuPanel {
            id: menu
            theme: testTheme
            items: [{ text: "First" }, { text: "Disabled", enabled: false }, { text: "Third" }]
            onTriggered: index => testRoot.triggeredIndex = index
        }
        PanelTransition {
            id: transition
            theme: testTheme
            direction: "up"
            Rectangle { width: 100; height: 100; color: "white" }
        }
    }

    function check(condition, message) {
        if (!condition) {
            failures++
            console.error("FAIL: " + message)
        }
    }
    Timer {
        interval: 150
        running: true
        onTriggered: {
            testRoot.check(candidateList.count === 3 && candidateList.selectedRow !== null, "candidate list resolves selection")
            testRoot.initialCandidate = candidateList.itemAt(0)
            testRoot.initialWidth = candidateList.measuredWidth
            testRoot.widthChanges = 0
            testRoot.candidates = JSON.parse(JSON.stringify(testRoot.candidates))
            candidateList.selectedIndex = 2
            transition.shown = true
            for (let i = 0; i < 5; ++i) list.moveSelection(1)
            menu.moveSelection(1)
            testRoot.check(menu.currentIndex === 2, "menu skips disabled rows")
            menu.activateCurrent()
            testRoot.check(testRoot.triggeredIndex === 2, "menu activates selected record")
            inFlight.restart()
        }
    }
    Timer {
        id: inFlight
        interval: 35
        onTriggered: {
            const destination = candidateList.selectedRow.y - testTheme.geometry.insetCurveRadius
            testRoot.check(candidateList.selectionY > -testTheme.geometry.insetCurveRadius
                && candidateList.selectionY < destination, "candidate highlight moves through intermediate positions")
            testRoot.check(candidateList.itemAt(0) === testRoot.initialCandidate, "cursor-only update retains candidate delegate")
            testRoot.check(testRoot.widthChanges === 0 && candidateList.measuredWidth === testRoot.initialWidth,
                           "cursor-only update does not shrink or remeasure width")
            testRoot.check(list.contentY > 0 && list.contentY < 114, "list scroll advances continuously")
            testRoot.check(transition.visible && transition.progress > 0 && transition.progress < 1,
                           "appearance starts from hidden state")
            testRoot.beforeRetarget = transition.progress
            transition.shown = false
            testRoot.check(!transition.enabled && transition.visible, "closing disables input while retaining content")
            testRoot.check(Math.abs(transition.progress - testRoot.beforeRetarget) < 0.02,
                           "closing retargets from current appearance without snapping")
            settle.restart()
        }
    }
    Timer {
        id: settle
        interval: 230
        onTriggered: {
            testRoot.check(Math.abs(candidateList.selectionY - 75) < 1, "candidate highlight settles at selected row")
            testRoot.check(testRoot.listIndex === 5 && Math.abs(list.contentY - 114) < 1,
                           "list preserves keyboard selection during scroll")
            testRoot.check(!transition.visible && transition.progress === 0, "closing finishes before hiding")
            testRoot.check(entries.count === 10, "stable model preserves all entries")
            const next = JSON.parse(JSON.stringify(testRoot.records))
            next[0].text = "Updated"
            testRoot.records = next
            testRoot.check(entries.get(0).entry.text === "Updated", "stable model updates display data")
            for (let i = 0; i < 4; ++i) list.moveSelection(1)
            list.moveSelection(1)
            bounceCheck.restart()
        }
    }
    Timer {
        id: bounceCheck
        interval: 300
        onTriggered: {
            testRoot.check(testRoot.listIndex === 9 && Math.abs(list.bounceOffset) < 0.5,
                           "edge bounce returns without wrapping")
            testRoot.check(list.contentY >= 0 && list.contentY <= list.maximumScroll,
                           "edge bounce keeps viewport offset in bounds")
            candidateList.horizontal = true
            candidateList.maximumWidth = 240
            candidateList.selectedIndex = 1
            horizontalCheck.restart()
        }
    }
    Timer {
        id: horizontalCheck
        interval: 170
        onTriggered: {
            testRoot.check(candidateList.selectedRow !== null
                && Math.abs(candidateList.selectionY - candidateList.selectedRow.y) < 1,
                           "horizontal candidate selection follows wrapped layout")
            testRoot.candidates = []
            emptyCheck.restart()
        }
    }
    Timer {
        id: emptyCheck
        interval: 50
        onTriggered: {
            testRoot.check(candidateList.count === 0 && candidateList.selectedRow === null,
                           "empty candidate list clears highlight")
            console.log(testRoot.failures === 0 ? "PASS: UI kit checks" : "FAIL: " + testRoot.failures + " UI kit checks")
            Qt.quit()
        }
    }
}
