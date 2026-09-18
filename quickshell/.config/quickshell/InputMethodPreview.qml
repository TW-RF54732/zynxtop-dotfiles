import QtQuick
import Quickshell
import "services"

ShellRoot {
    Style { id: theme }
    QtObject { id: compositor; property var activeWindow: null }
    InputMethodService {
        id: inputMethod
        enabled: false
        snapshot: ({ connected: true, showPreedit: true, preedit: "ㄓㄨㄥ ㄨㄣˊ",
            showCandidates: true, candidates: [
                { label: "1", text: "中文", selectable: true },
                { label: "2", text: "中聞", selectable: true },
                { label: "3", text: "忠文", selectable: true }],
            selectedIndex: 0, hasPrev: false, hasNext: true,
            position: { valid: true, x: 100, y: 120, top: 100 } })
        function select(index) {
            const next = Object.assign({}, snapshot)
            next.selectedIndex = index
            snapshot = next
        }
    }
    InputMethodWindow { theme: theme; inputMethod: inputMethod; compositor: compositor }
    Timer { running: true; interval: 2500; onTriggered: Qt.quit() }
}
