import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property string displayName: Quickshell.env("USER") || "使用者"
    property string avatar: ""
    Process {
        running: true
        command: ["python3", Qt.resolvedUrl("user_info.py").toString().replace(/^file:\/\//, "")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const info = JSON.parse(text);
                    root.displayName = info.displayName || root.displayName;
                    root.avatar = info.avatar || "";
                } catch (error) { /* Keep the account-name fallback. */ }
            }
        }
    }
}
