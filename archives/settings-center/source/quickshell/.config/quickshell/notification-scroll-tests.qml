import QtQuick
import QtQuick.Window
import Quickshell
import "services"
import "dashboard"
ShellRoot {
    id: root
    property var list: null
    property var block: null
    property var otherBlock: null
    property real headerHeight: 0
    property real fullHeight: 0
    property real initialY: 0
    property real previousY: 0
    property int samples: 0
    property real maxStep: 0
    property int failures: 0
    function check(value, message) {
        if (!value) { failures++; console.error("FAIL: " + message) }
    }
    Style { id: style }
    NotificationService { id: service }
    Window {
        width: 400; height: 340; visible: true
        NotificationCenter { id: center; theme: style; notifications: service; anchors.fill: parent; anchors.margins: 20 }
    }
    Timer {
        interval: 50; running: true
        onTriggered: {
            service.history = Array.from({length: 12}, (_, i) => ({key: String(i),appName:"Test",source:"test",summary:"Test",body:"Body",timestamp:Date.now(),read:false}))
            root.list = center.children.find(child => child.objectName === "notificationHistoryList")
            ready.start()
        }
    }
    Timer {
        id: ready; interval: 60
        onTriggered: {
            root.block = root.list.itemAtIndex(0).children.find(child => child.objectName === "notificationBlock:test")
            root.headerHeight = root.block.headerHeight
            root.fullHeight = root.block.fullContentHeight
            root.initialY = root.list.contentY
            center.toggleGroup("test")
            opening.start()
            opened.start()
        }
    }
    Timer {
        id: opening; interval: 100
        onTriggered: {
            root.check(root.block.headerHeight === root.headerHeight, "opening keeps source header fixed")
            root.check(root.block.revealHeight > 0 && root.block.revealHeight < root.fullHeight,
                "opening reveals one continuous viewport")
            root.check(root.block.fullContentHeight === root.fullHeight, "opening does not resize individual messages")
            root.check(Math.abs(root.list.contentY - root.initialY) < 1, "opening holds viewport")
            console.log("PASS: top-down expansion with fixed viewport")
        }
    }
    Timer {
        id: opened; interval: 400
        onTriggered: {
            root.check(Math.abs(root.block.revealHeight - root.fullHeight) < 1, "group fully expands")
            root.list.positionViewAtEnd()
            root.initialY = root.list.contentY - root.list.originY
            root.previousY = root.initialY
            center.toggleGroup("test")
            sampling.start()
            closing.start()
            closed.start()
        }
    }
    Timer {
        id: closing; interval: 100
        onTriggered: {
            root.check(root.block.headerHeight === root.headerHeight && root.block.fullContentHeight === root.fullHeight,
                "closing keeps header and child positions fixed")
            root.check(root.block.revealHeight > 0 && root.block.revealHeight < root.fullHeight,
                "closing clips the bottom of the shared viewport")
            console.log("PASS: bottom-up collapse retains earlier notifications")
        }
    }
    Timer {
        id: sampling; interval: 16; repeat: true
        onTriggered: {
            const position = root.list.contentY - root.list.originY
            root.maxStep = Math.max(root.maxStep, Math.abs(position - root.previousY))
            root.previousY = position
            root.samples++
        }
    }
    Timer {
        id: closed; interval: 500
        onTriggered: {
            sampling.stop()
            root.check(root.initialY > 100 && root.samples > 10 && Math.abs(root.list.contentY - root.list.originY) < 1
                && root.maxStep < root.initialY * 0.3 && service.unreadCount === 12,
                "bottom collapse follows shrinking content without jumps or marking unread messages")
            root.check(root.block.revealHeight === 0, "closed content occupies no space")
            center.toggleGroup("test")
            reverse.start()
        }
    }
    Timer {
        id: reverse; interval: 90
        onTriggered: {
            const before = root.block.revealHeight
            center.toggleGroup("test")
            root.check(Math.abs(before - root.block.revealHeight) < 1, "closing reversal keeps current geometry")
            reopen.start()
        }
    }
    Timer {
        id: reopen; interval: 50
        onTriggered: {
            const before = root.block.revealHeight
            center.toggleGroup("test")
            root.check(Math.abs(before - root.block.revealHeight) < 1, "opening reversal keeps current geometry")
            settled.start()
        }
    }
    Timer {
        id: settled; interval: 400
        onTriggered: {
            root.check(Math.abs(root.block.revealHeight - root.fullHeight) < 1, "rapid reversal settles expanded")
            service.history = service.history.concat([0, 1].map(i => ({key: "other" + i, appName: "Other", source: "other",
                summary: "Other", body: "Other body", timestamp: Date.now(), read: false})))
            switchReady.start()
        }
    }
    Timer {
        id: switchReady; interval: 60
        onTriggered: {
            root.otherBlock = root.list.itemAtIndex(1).children.find(child => child.objectName === "notificationBlock:other")
            center.toggleGroup("other")
            switching.start()
        }
    }
    Timer {
        id: switching; interval: 90
        onTriggered: {
            const firstHeight = root.block.revealHeight
            const secondHeight = root.otherBlock.revealHeight
            root.check(firstHeight > 0 && firstHeight < root.fullHeight && secondHeight > 0,
                "source switch independently closes the old block and opens the new one")
            center.toggleGroup("test")
            root.check(Math.abs(firstHeight - root.block.revealHeight) < 1
                && Math.abs(secondHeight - root.otherBlock.revealHeight) < 1,
                "rapid source switch does not reset either block's height")
            switchSettled.start()
        }
    }
    Timer {
        id: switchSettled; interval: 400
        onTriggered: {
            root.check(Math.abs(root.block.revealHeight - root.fullHeight) < 1 && root.otherBlock.revealHeight === 0,
                "source switch settles with only the selected block expanded")
            console.log(root.failures ? "FAIL: scroll recovery" : "PASS: smooth scroll recovery")
            Qt.quit()
        }
    }
}
