import QtQuick
import Quickshell.Io

JsonProcessService {
    id: root
    property var status: ({})
    property string actionError: ""
    readonly property bool busy: actionProcess.running
    command: ["python3", Qt.resolvedUrl("system_status.py").toString().replace("file://", "")]
    onMessageReceived: message => status = message
    onDisconnected: status = ({})
    function act(action) {
        const commands = {
            suspend: ["systemctl", "suspend"], hibernate: ["systemctl", "hibernate"],
            reboot: ["systemctl", "reboot"], poweroff: ["systemctl", "poweroff"],
            lock: ["hyprlock"]
        }
        if (busy || !status.capabilities || !status.capabilities[action] || !commands[action]) return
        actionError = ""
        actionProcess.command = commands[action]
        actionProcess.running = true
    }
    Process {
        id: actionProcess
        stderr: StdioCollector { onStreamFinished: root.actionError = text.trim() }
        onExited: exitCode => {
            if (exitCode !== 0 && !root.actionError) root.actionError = "FAILED (" + exitCode + ")"
        }
    }
}
