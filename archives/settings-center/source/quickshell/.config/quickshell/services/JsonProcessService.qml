import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    required property list<string> command
    property bool enabled: true
    property int retryInterval: 10000
    readonly property bool running: transport.running
    property string error: ""
    signal messageReceived(var message)
    signal disconnected()

    function send(message) {
        if (transport.running) transport.write(JSON.stringify(message) + "\n")
    }
    onEnabledChanged: {
        retry.stop()
        transport.running = enabled
    }
    Component.onCompleted: transport.running = enabled

    Process {
        id: transport
        command: root.command
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                try { root.messageReceived(JSON.parse(data)) }
                catch (exception) { root.error = "Invalid JSON from service: " + exception }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) root.error = text.trim()
        }
        onStarted: root.error = ""
        onExited: {
            root.disconnected()
            if (root.enabled) retry.restart()
        }
    }
    Timer {
        id: retry
        interval: root.retryInterval
        onTriggered: transport.running = root.enabled
    }
}
