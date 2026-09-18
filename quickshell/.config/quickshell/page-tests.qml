import QtQuick
import Quickshell
import "services"
import "inputmethod"
ShellRoot {
    id: root
    property int failures: 0
    property real tallHeight: 0
    function check(value, text) { if (!value) { failures++; console.error("FAIL: " + text) } }
    function snapshot(text, previous) { return {connected:true,showCandidates:true,showPreedit:true,preedit:"test",candidates:[{label:"1",text:text,selectable:true}],selectedIndex:0,hasPrev:previous,hasNext:true} }
    Style { id: theme }
    InputMethodService { id: ime; enabled: false }
    Item {
        width: 400; height: 400
        CandidatePages { id: pages; theme: theme; width: 240; candidates: ime.candidates; selectedIndex: ime.selectedIndex; pageNumber: ime.pageNumber; pageDirection: ime.pageDirection; pageRevision: ime.pageRevision }
    }
    Timer {
        interval: 100; running:true
        onTriggered: { ime.applySnapshot(root.snapshot("first", false)); first.restart() }
    }
    Timer {
        id: first; interval: 100
        onTriggered: {
            root.check(ime.pageNumber === 1 && !pages.animating, "initial page does not slide")
            ime.applySnapshot(root.snapshot("second", true))
            ime.applySnapshot(root.snapshot("second", true))
            inFlight.restart()
        }
    }
    Timer {
        id: inFlight; interval: 40
        onTriggered: {
            root.check(ime.pageNumber === 2 && pages.animating && pages.direction === 1 && pages.progress > 0 && pages.progress < 1, "confirmed next page slides left")
            root.check(pages.activeList.candidates[0].text === "second", "incoming page uses new records")
            settle.restart()
        }
    }
    Timer {
        id: settle; interval: 220
        onTriggered: {
            root.check(!pages.animating && pages.progress === 1, "page animation settles")
            ime.applySnapshot(root.snapshot("second", true))
            root.check(ime.pageNumber === 2 && !pages.animating, "same-page snapshot keeps page and does not animate")
            ime.applySnapshot(root.snapshot("first", false))
            back.restart()
        }
    }
    Timer {
        id: back; interval: 40
        onTriggered: {
            root.check(ime.pageNumber === 1 && pages.animating && pages.direction === -1, "return to first page slides right")
            ime.applySnapshot(root.snapshot("second", true))
            rapid.restart()
        }
    }
    Timer {
        id: rapid; interval: 240
        onTriggered: {
            root.check(!pages.animating && pages.activeList.candidates[0].text === "second", "rapid reversal settles on newest page")
            const tall = root.snapshot("tall", false)
            tall.candidates = Array.from({length: 10}, (_, i) => ({label:String((i + 1) % 10),text:"candidate " + i,selectable:true}))
            ime.applySnapshot(tall)
            tallCheck.restart()

        }
    }
    Timer {
        id: tallCheck; interval: 100
        onTriggered: {
            root.tallHeight = pages.implicitHeight
            root.check(root.tallHeight === theme.inputMethod.maxVisibleRows * theme.inputMethod.rowHeight, "full page keeps seven-row viewport")
            ime.applySnapshot(root.snapshot("short", true))
            shortCheck.restart()
        }
    }
    Timer {
        id: shortCheck; interval: 240
        onTriggered: {
            root.check(pages.implicitHeight === root.tallHeight && pages.activeList.candidates.length === 1,
                "short page preserves height after animation finishes")
            ime.applySnapshot(root.snapshot("new composition", false))
            resetCheck.restart()
        }
    }
    Timer {
        id: resetCheck; interval: 100
        onTriggered: {
            root.check(pages.implicitHeight === theme.inputMethod.rowHeight, "new first-page content resets retained height")
            console.log(root.failures ? "FAIL: page checks" : "PASS: page checks")
            Qt.quit()
        }
    }
}
