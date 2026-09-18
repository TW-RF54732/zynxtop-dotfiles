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
    function applySnapshot(message) {
        const next = Object.assign({}, message)
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
    function previousPage() { if (connected && hasPrevious) send({ action: "previous" }) }
    function nextPage() { if (connected && hasNext) send({ action: "next" }) }
}
