import QtQuick
import Quickshell
import "services"
import "launcher"
import "components"
import "examples"
import "inputmethod"
import "topbar"

ShellRoot {
    id: testRoot
    property int failures: 0
    property int closeRequests: 0
    property var launched: null
    property string command: ""
    property int candidatePages: 0
    property var entries: [
        { id: "beta", name: "Beta", genericName: "Editor", keywords: ["code"], noDisplay: false },
        { id: "alpha", name: "Alpha", genericName: "", keywords: [], noDisplay: false },
        { id: "hidden", name: "Alpha hidden", noDisplay: true }
    ]

    Style { id: testTheme }
    QtObject { id: trackedWindow; property string title: "Agent working" }
    QtObject { id: otherWindow; property string title: "Editor" }
    ApplicationsService {
        id: apps
        function search(query, showAll) { return rankEntries(testRoot.entries, query, showAll) }
        function launch(app) { testRoot.launched = app }
        function executeCommand(value) { testRoot.command = value }
    }
    LauncherController {
        id: controller
        applications: apps
        onCloseRequested: testRoot.closeRequests++
    }
    AudioService { id: audioService }
    NetworkService { id: networkService }
    ClockService { id: clockService }
    InputMethodService { id: ime; enabled: false }
    AnimatedVisibility { id: popupVisibility; duration: testTheme.motion.fastDuration }
    PopupPlacement {
        id: placement
        availableWidth: 1000; availableHeight: 800
        popupWidth: 240; popupHeight: 300
        cursorValid: true; cursorX: 980; cursorBottom: 780; cursorTop: 760
    }

    Item {
        id: host
        width: 720
        height: 600
        SearchField { id: field; theme: testTheme; width: host.width }
        ActiveWindow {
            id: windowTitle
            theme: testTheme
            width: host.width
            activeWindow: trackedWindow
            windows: [trackedWindow, otherWindow]
        }
        ResultsList {
            id: list
            theme: testTheme
            width: host.width
            results: controller.results
            selectedIndex: controller.selectedIndex
            onSelectionRequested: index => controller.selectedIndex = index
        }
        Separator { id: horizontal; theme: testTheme; width: host.width }
        Separator { id: vertical; theme: testTheme; vertical: true; length: 20 }
        AudioPanel { id: example; theme: testTheme; audio: audioService }
        CandidatePanel { id: imePanel; theme: testTheme; inputMethod: ime }
        RevealSurface {
            id: reveal
            theme: testTheme; shown: popupVisibility.shown
            expandedWidth: 250; expandedHeight: 150
        }
        CandidateList {
            id: imeList
            theme: testTheme
            width: 250
            onPageRequested: direction => testRoot.candidatePages += direction
        }
    }

    function check(condition, message) {
        if (!condition) {
            failures++
            console.error("FAIL: " + message)
        }
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            testRoot.check(!windowTitle.pinned && windowTitle.title === "Agent working",
                "window title follows active window by default")
            windowTitle.togglePin()
            windowTitle.activeWindow = otherWindow
            trackedWindow.title = "Agent finished"
            testRoot.check(windowTitle.pinned && windowTitle.title === "Agent finished",
                "pinned window keeps updating its title after focus changes")
            windowTitle.togglePin()
            testRoot.check(!windowTitle.pinned && windowTitle.title === "Editor",
                "clicking again restores active window tracking")
            windowTitle.activeWindow = trackedWindow
            windowTitle.togglePin()
            windowTitle.activeWindow = otherWindow
            windowTitle.windows = [otherWindow]
            testRoot.check(!windowTitle.pinned && windowTitle.pinnedWindow === null
                && windowTitle.title === "Editor", "closed pinned window restores active window tracking")
            windowTitle.activeWindow = null
            windowTitle.togglePin()
            testRoot.check(!windowTitle.pinned && !windowTitle.visible,
                "no active window leaves title hidden and unpinned")
            popupVisibility.requestedVisible = true
            const candidateItems = []
            for (let i = 0; i < 10; ++i)
                candidateItems.push({ label: String(i + 1), text: "候選 " + i, selectable: true })
            imeList.candidates = candidateItems
            imeList.selectedIndex = 9
            candidateScrollCheck.restart()
            testRoot.check(!ime.visible && !ime.running, "disabled input method does not claim desktop service")
            ime.snapshot = { connected: true, showPreedit: true, preedit: "ㄓㄨㄥ",
                showCandidates: true, candidates: [
                    { label: "1", text: "中文", selectable: true },
                    { label: "2", text: "中午", selectable: true }], selectedIndex: 1,
                hasPrev: false, hasNext: true, layout: 0 }
            testRoot.check(ime.visible && ime.preedit === "ㄓㄨㄥ" && ime.candidates.length === 2
                && ime.selectedIndex === 1 && ime.hasNext, "input method maps composition and candidates")
            const originalCandidates = ime.candidates
            ime.applySnapshot(JSON.parse(JSON.stringify(ime.snapshot)))
            testRoot.check(ime.candidates === originalCandidates,
                "caret-only snapshots preserve candidate model identity")
            imeCheck.restart()
            testRoot.check(placement.x === 752 && placement.y === 454,
                "popup clamps at right edge and flips above caret")
            placement.cursorValid = false
            testRoot.check(placement.x === 380 && placement.y === 492,
                "popup has deterministic fallback when caret is unavailable")
            testRoot.check(field.height === testTheme.launcher.searchHeight, "search field keeps height")
            testRoot.check(list.height === testTheme.launcher.emptyResultHeight, "empty list keeps height")
            testRoot.check(horizontal.height === 1 && vertical.width === 1 && vertical.height === 20,
                  "separator orientations keep dimensions")
            testRoot.check(example.width === 300 && example.height === 60, "composition example loads")
            testRoot.check(clockService.displayDate instanceof Date, "shared clock exposes date")
            testRoot.check(typeof networkService.offline === "boolean", "shared network exposes status")
            testRoot.check(apps.search("", false).length === 0, "empty search is collapsed")
            testRoot.check(apps.search("> command", true).length === 0, "commands bypass application search")
            testRoot.check(apps.score(testRoot.entries[0], "beta") === 1000, "exact match rank")
            testRoot.check(apps.score(testRoot.entries[0], "bt") >= 0, "fuzzy match rank")
            testRoot.check(apps.score(testRoot.entries[0], "xyz") === -1, "unmatched search")
            testRoot.check(apps.score(testRoot.entries[0], "editor") === 180, "generic name rank")
            testRoot.check(apps.score(testRoot.entries[0], "code") === 100, "keyword rank")
            testRoot.check(apps.normalizedAppId("org.Example-App.desktop") === "orgexampleapp", "tray id normalization")
            controller.showAllApplications()
            testRoot.check(controller.expanded && controller.results.length === 2, "Tab excludes hidden apps")
            testRoot.check(controller.results[0].app.id === "alpha", "equal usage sorts by name")
            list.moveSelection(1)
            testRoot.check(controller.selectedIndex === 1, "list requests next selection")
            list.moveSelection(1)
            testRoot.check(controller.selectedIndex === 1, "list does not wrap at last result")
            controller.activate()
            testRoot.check(testRoot.launched.id === "beta" && testRoot.closeRequests === 1, "selected app activation closes")
            controller.query = "ALPHA"
            testRoot.check(!controller.showAll && controller.results.length === 1 && controller.selectedIndex === 0,
                  "query filters, disables show-all, and clamps selection")
            controller.query = ">   printf test  "
            controller.activate()
            testRoot.check(testRoot.command === "printf test" && testRoot.closeRequests === 2, "command trim and close")
            controller.query = ">"
            controller.activate()
            testRoot.check(testRoot.command === "" && testRoot.closeRequests === 3, "empty command closes")
            controller.reset()
            testRoot.check(!controller.expanded && controller.results.length === 0 && controller.selectedIndex === 0,
                  "reset clears controller")
            apps.recordLaunch(testRoot.entries[0])
            testRoot.check(apps.usageCount(testRoot.entries[0]) === 1, "usage count updates")
            testRoot.check(apps.search("", true)[0].app.id === "beta", "usage changes show-all ordering")
            testRoot.check(apps.search("alpha", false)[0].app.id === "alpha", "text match dominates usage")
            const more = []
            for (let i = 0; i < 8; ++i)
                more.push({ id: "extra" + i, name: "Extra " + i, noDisplay: false })
            testRoot.entries = testRoot.entries.concat(more)
            controller.showAllApplications()
            list.positionViewAtBeginning()
            scrollSetup.restart()
        }
    }

    Timer {
        id: candidateScrollCheck
        interval: 250
        onTriggered: {
            testRoot.check(imeList.height === testTheme.inputMethod.maxVisibleRows * testTheme.inputMethod.rowHeight,
                "candidate list limits viewport to seven rows")
            testRoot.check(Math.abs(imeList.contentY - 120) < 1,
                "moving candidate selection smoothly reveals bottom rows")
            testRoot.check(popupVisibility.mounted && popupVisibility.shown && Math.abs(reveal.width - 250) < 1,
                "popup mounts and finishes shell reveal animation")
            imeList.handleWheel({ angleDelta: { x: 0, y: 120 }, pixelDelta: { x: 0, y: 0 } })
            testRoot.check(testRoot.candidatePages === 0, "vertical wheel never pages candidates")
            imeList.handleWheel({ angleDelta: { x: -120, y: 0 }, pixelDelta: { x: 0, y: 0 } })
            testRoot.check(testRoot.candidatePages === 1, "horizontal wheel pages candidates")
            popupVisibility.requestedVisible = false
            testRoot.check(popupVisibility.mounted && !popupVisibility.shown,
                "popup stays mounted throughout close animation")
            candidateCloseCheck.restart()
        }
    }
    Timer {
        id: candidateCloseCheck
        interval: 250
        onTriggered: {
            testRoot.check(Math.abs(imeList.contentY - 80) < 1,
                "vertical wheel scrolls exactly one candidate row")
            imeList.candidates = JSON.parse(JSON.stringify(imeList.candidates))
            testRoot.check(Math.abs(imeList.contentY - 80) < 1,
                "same-page snapshots do not rewind candidate scrolling")
            testRoot.check(!popupVisibility.mounted && reveal.width === 0 && reveal.opacity === 0,
                "popup unmounts after close animation completes")
        }
    }
    Timer {
        id: imeCheck
        interval: 30
        onTriggered: {
            testRoot.check(imePanel.implicitWidth >= testTheme.inputMethod.minWidth
                && imePanel.implicitHeight >= 80, "candidate panel composes reusable modules: "
                    + imePanel.implicitWidth + " x " + imePanel.implicitHeight)
            ime.snapshot = { connected: false }
            testRoot.check(!ime.visible && ime.candidates.length === 0 && ime.preedit === "",
                "backend disconnect hides stale input method data")
        }
    }
    Timer {
        id: scrollSetup
        interval: 300
        onTriggered: {
            testRoot.check(list.height === testTheme.launcher.maxVisibleResults * testTheme.launcher.resultHeight,
                           "long list keeps seven-row viewport")
            testRoot.check(list.contentHeight === 10 * testTheme.launcher.resultHeight,
                           "long list keeps all results")
            for (let i = 0; i < 7; ++i) list.moveSelection(1)
            scrollCheck.restart()
        }
    }
    Timer {
        id: scrollCheck
        interval: 250
        onTriggered: {
            const maximum = list.contentHeight - list.height
            testRoot.check(controller.selectedIndex === 7 && Math.abs(list.contentY - maximum) < 1,
                           "leaving visible edge scrolls and clamps to list extent")
            list.moveSelection(1)
            list.moveSelection(1)
            list.moveSelection(1)
            bottomBounceCheck.restart()
        }
    }
    Timer {
        id: bottomBounceCheck
        interval: 300
        onTriggered: {
            testRoot.check(controller.selectedIndex === 9,
                           "bottom bounce keeps final selection")
            testRoot.check(Math.abs(list.contentY - (list.contentHeight - list.height)) < 1,
                           "bottom bounce returns to extent")
            controller.showAllApplications()
            list.positionViewAtBeginning()
            topBounceSetup.restart()
        }
    }
    Timer {
        id: topBounceSetup
        interval: 100
        onTriggered: {
            list.moveSelection(-1)
            topBounceCheck.restart()
        }
    }
    Timer {
        id: topBounceCheck
        interval: 300
        onTriggered: {
            testRoot.check(controller.selectedIndex === 0 && Math.abs(list.contentY) < 1,
                           "top bounce returns without wrapping")
            console.log(testRoot.failures === 0 ? "PASS: modular shell smoke checks"
                        : "FAIL: " + testRoot.failures + " smoke checks")
            Qt.quit()
        }
    }
}
