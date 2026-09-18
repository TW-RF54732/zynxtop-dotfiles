import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "services"
import "dashboard"

ShellRoot {
    Style { id: style }
    NotificationService { id: service }
    Window {
        width: 560; height: 340; visible: true
        NotificationCenter { id: center; theme: style; notifications: service; anchors.fill: parent; anchors.margins: 20 }
        Timer { interval: 100; running: true; onTriggered: pointer.exercise() }
        TestCase {
            id: pointer
            name: "NotificationClick"
            when: false
            function face(key) {
                const list = center.children.find(child => child.objectName === "notificationHistoryList")
                const row = list.itemAtIndex(center.modelRows.findIndex(entry => entry.key === key))
                return row.children.find(child => child.objectName === "notificationFace:" + key)
            }
            function exercise() {
                service.history = [0, 1].map(i => ({key: String(i), source: "test", appName: "Test", summary: "Test",
                    body: "Short body", timestamp: Date.now(), read: false}))
                wait(650)
                // Click the body, where the inner Flickable used to cover the hit area.
                const stack = face("group:test")
                mouseClick(stack, 80, 82, Qt.LeftButton)
                compare(center.expandedSource, "test")
                wait(650)
                const message = face("0")
                mouseClick(message, 80, 58, Qt.LeftButton)
                compare(center.expandedKey, "0")
                mouseClick(message, 80, 58, Qt.LeftButton)
                compare(center.expandedKey, "0")
                verify(!service.history[0].read)
                mouseClick(message, 80, 58, Qt.RightButton)
                compare(center.expandedKey, "")
                verify(service.history[0].read)
                console.log("PASS: notification single-click handling")
                Qt.quit()
            }
        }
    }
}
