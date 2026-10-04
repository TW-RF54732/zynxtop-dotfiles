import QtQuick
import Quickshell
import "settings"
import "services"
ShellRoot {
    Style { id: theme }
    AudioService { id: audio }
    WireGuardService { id: wireguard }
    SettingsWindow { id: window; theme: theme; audio: audio; wireguard: wireguard }
    Timer {
        interval: 200; repeat: true; running: true
        property int attempts: 0
        onTriggered: {
            attempts++
            if (window.ready) {
                if (window.snapshot.pages.length !== 15) throw new Error("Missing pages")
                if (window.dirty) throw new Error("First open must be read-only")
                window.edit("typography.bodySize", 19)
                if (!window.dirty) throw new Error("Draft not tracked")
                window.changes = ({})
                console.log("PASS: settings window and backend loaded; 15 pages; draft state")
                Qt.quit()
            }
            if (attempts > 60) { console.log("FAIL: settings backend did not become ready: " + window.status); Qt.quit() }
        }
    }
}
