import QtQuick
import Quickshell.Io

// Ends the process that owns a tray item. Opening an item stays a plain
// SystemTrayItem.activate() call; only termination needs the D-Bus lookup.
Item {
    id: root
    readonly property bool busy: process.running
    property string lastError: ""
    signal finished(var reply)

    function terminate(item) {
        if (busy || !item || !item.id) return
        lastError = ""
        process.command = ["python3", Qt.resolvedUrl("tray_process.py").toString().replace("file://", ""),
            String(item.id), String(item.title || "")]
        process.running = true
    }

    Process {
        id: process
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const reply = JSON.parse(text)
                    root.lastError = reply.ok ? "" : reply.error
                    if (root.lastError) clearError.restart()
                    root.finished(reply)
                } catch (exception) {
                    root.lastError = "INVALID REPLY"
                    clearError.restart()
                }
            }
        }
    }
    Timer {
        id: clearError
        interval: 4000
        onTriggered: root.lastError = ""
    }
}
