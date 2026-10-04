import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property var values: ({})
    property string error: ""
    function value(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    property Timer retry: Timer { interval: 3000; repeat: true; running: true; onTriggered: root.source.reload() }
    property FileView source: FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/settings-center/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text())
                if (data.version !== 1 || !data.values || Array.isArray(data.values) || typeof data.values !== "object") throw new Error("Invalid settings")
                root.values = data.values
                root.error = ""
            } catch (e) { root.error = String(e) }
        }
        onLoadFailed: root.values = ({})
    }
}
