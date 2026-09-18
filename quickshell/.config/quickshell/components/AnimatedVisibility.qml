import QtQuick
import Quickshell

Scope {
    id: root
    property bool requestedVisible: false
    property int duration: 140
    property bool mounted: false
    property bool shown: false

    function synchronize() {
        if (requestedVisible) {
            closeTimer.stop()
            mounted = true
            Qt.callLater(() => { if (root.requestedVisible) root.shown = true })
        } else {
            shown = false
            if (mounted) closeTimer.restart()
        }
    }
    onRequestedVisibleChanged: synchronize()
    Component.onCompleted: synchronize()
    Timer {
        id: closeTimer
        interval: root.duration
        onTriggered: if (!root.requestedVisible) root.mounted = false
    }
}
