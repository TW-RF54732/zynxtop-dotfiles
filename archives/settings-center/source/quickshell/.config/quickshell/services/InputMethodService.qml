import QtQuick
import Quickshell
import Quickshell.Io

JsonProcessService {
    id: root
    command: ["bash", Qt.resolvedUrl("../inputmethod/bridge/run.sh").toString().replace(/^file:\/\//, ""),
        Quickshell.stateDir + "/bridges/fcitx"]
    property var snapshot: ({})
    readonly property bool connected: snapshot.connected === true
    readonly property string preedit: snapshot.showPreedit ? snapshot.preedit || "" : ""
    readonly property string auxiliary: snapshot.showAux ? snapshot.aux || "" : ""
    readonly property var candidates: snapshot.showCandidates ? snapshot.candidates || [] : []
    readonly property int selectedIndex: Number.isInteger(snapshot.selectedIndex) ? snapshot.selectedIndex : -1
    readonly property bool hasPrevious: snapshot.hasPrev === true
    readonly property bool hasNext: snapshot.hasNext === true
    readonly property int layoutHint: snapshot.layout || 0
    readonly property var cursorPosition: snapshot.position || ({ valid: false })
    readonly property bool visible: connected && (preedit.length > 0 || auxiliary.length > 0 || candidates.length > 0)
    property int pendingPageDirection: 0
    readonly property int pageNumber: snapshot.pageNumber || 1
    readonly property int pageDirection: snapshot.pageDirection || 0
    property var pageKeys: []
    readonly property int pageRevision: snapshot.pageRevision || 0
    function applySnapshot(message) {
        const next = Object.assign({}, message)
        const key = JSON.stringify(next.candidates || [])
        const changedPage = key !== JSON.stringify(snapshot.candidates || [])
        const opening = !snapshot.showCandidates || !snapshot.connected
        let direction = snapshot.pageDirection || 0
        let page = pageNumber
        let revision = pageRevision
        if (opening || !next.showCandidates || !next.connected) {
            page = 1
            direction = 0
            pageKeys = []
        } else if (changedPage) {
            const knownPage = pageKeys.indexOf(key) + 1
            direction = pendingPageDirection
            if (!next.hasPrev) {
                if (direction === 0 && page > 1 && knownPage === 1) direction = -1
                page = 1
                if (direction === 0) pageKeys = []
            } else if (direction !== 0) page = Math.max(1, page + direction)
            else if (knownPage > 0) {
                direction = Math.sign(knownPage - page)
                page = knownPage
            } else {
                // Keyboard paging bypasses our buttons; a new non-first page
                // is discovered from the lookup-table response itself.
                direction = 1
                page += 1
            }
            if (direction !== 0) revision += 1
        }
        if (changedPage || opening) {
            const keys = pageKeys.slice()
            keys[page - 1] = key
            pageKeys = keys
            pendingPageDirection = 0
        }
        next.pageNumber = page
        next.pageDirection = direction
        next.pageRevision = revision
        // Caret polling and cursor-only changes must not recreate or rewind the list.
        if (JSON.stringify(next.candidates) === JSON.stringify(snapshot.candidates))
            next.candidates = snapshot.candidates
        snapshot = next
    }
    onMessageReceived: message => applySnapshot(message)
    onDisconnected: snapshot = ({})

    IpcHandler {
        target: "inputmethod"
        function status(): string {
            return JSON.stringify({ connected: root.connected, visible: root.visible,
                cursorPositionAvailable: root.cursorPosition.valid === true,
                cursorPosition: root.cursorPosition, layoutHint: root.layoutHint, error: root.error })
        }
    }

    function select(index) {
        if (connected && index >= 0 && index < candidates.length && candidates[index].selectable)
            send({ action: "select", index: index })
    }
    function previousPage() { if (connected && hasPrevious) { pendingPageDirection = -1; send({ action: "previous" }) } }
    function nextPage() { if (connected && hasNext) { pendingPageDirection = 1; send({ action: "next" }) } }
}
