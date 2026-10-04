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
        width: 400; height: 720; visible: true
        NotificationCenter { id: center; theme: style; notifications: service; anchors.fill: parent; anchors.margins: 20 }
        Timer { interval: 100; running: true; onTriggered: pointer.exercise() }
        TestCase {
            id: pointer
            name: "NotificationClick"
            when: false
            function block(source) {
                const list = center.children.find(child => child.objectName === "notificationHistoryList")
                const index = center.groups.findIndex(group => group.key === source)
                list.positionViewAtIndex(index, ListView.Beginning)
                wait(30)
                return findChild(list.itemAtIndex(index), "notificationBlock:" + source)
            }
            function record(key, source, read) {
                return {key: key, source: source, appName: source, summary: "Test", body: "Short body", timestamp: Date.now(), read: read || false}
            }
            function exercise() {
                service.history = [record("0", "test"), record("1", "test"), record("other", "other"), record("read", "test", true)]
                service.history[0].body = "Long notification detail. ".repeat(80)
                service.history = service.history.slice()
                wait(350)
                let group = block("test")
                let header = findChild(group, "notificationHeader:test")
                // Same header opens and closes, including clicks on preview text.
                mouseClick(header, 80, 58, Qt.LeftButton)
                compare(center.expandedSource, "test")
                wait(350)
                mouseClick(header, 80, 58, Qt.LeftButton)
                compare(center.expandedSource, "")
                wait(350)
                mouseClick(header, 80, 58, Qt.LeftButton)
                wait(350)
                let message = findChild(group, "notificationFace:0")
                mouseClick(message, 80, 58, Qt.LeftButton)
                compare(center.expandedKey, "0")
                wait(100)
                verify(Math.abs(group.revealHeight - group.fullContentHeight) < 1,
                    "open dropdown tracks detail height without a second trailing animation")
                mouseClick(message, 80, 58, Qt.LeftButton)
                compare(center.expandedKey, "0")
                verify(!service.history[0].read)
                mouseClick(message, 80, 58, Qt.RightButton)
                compare(center.expandedKey, "")
                verify(service.history[0].read)
                wait(350)
                // One remaining unread message still has a block delete button.
                group = block("test")
                let remove = findChild(group, "deleteNotificationGroup:test")
                mouseClick(remove, 15, 14, Qt.LeftButton)
                wait(350)
                verify(!service.history.some(item => item.key === "1"))
                verify(service.history.some(item => item.key === "0" && item.read))
                verify(service.history.some(item => item.key === "read" && item.read))
                verify(service.history.some(item => item.key === "other" && !item.read))
                // Delete an entire expanded source without touching its read history.
                service.history = [record("a", "test"), record("b", "test"), record("other", "other"), record("read", "test", true)]
                wait(350)
                group = block("test")
                header = findChild(group, "notificationHeader:test")
                mouseClick(header, 80, 58, Qt.LeftButton)
                wait(350)
                remove = findChild(group, "deleteNotificationGroup:test")
                mouseClick(remove, 15, 14, Qt.LeftButton)
                wait(350)
                compare(center.expandedSource, "")
                compare(service.history.length, 2)
                verify(service.history.some(item => item.key === "read"))
                compare(center.groups.length, 1)
                compare(center.groups[0].key, "other")
                // Closed groups expose the same deletion action.
                service.history = [record("c", "test"), record("d", "test"), record("other", "other")]
                wait(350)
                group = block("test")
                remove = findChild(group, "deleteNotificationGroup:test")
                mouseClick(remove, 15, 14, Qt.LeftButton)
                wait(350)
                compare(service.history.length, 1)
                compare(service.history[0].key, "other")
                console.log("PASS: notification single-click handling")
                console.log("PASS: source block deletion preserves other sources and read history")
                Qt.quit()
            }
        }
    }
}
