import QtQuick
import QtQuick.Window
import Quickshell
import "services"
import "dashboard"
ShellRoot {
    id: root
    property var list: null
    property real initialY: 0
    property real previousY: 0
    property int samples: 0
    property real maxStep: 0
    Style { id: style }
    NotificationService { id: service }
    Window {
        width: 560; height: 340; visible: true
        NotificationCenter { id: center; theme: style; notifications: service; anchors.fill: parent; anchors.margins: 20 }
    }
    Timer {
        interval: 50; running: true
        onTriggered: {
            const records = []
            for (let i = 0; i < 12; ++i) records.push({key: String(i),appName:"Test",source:"test",summary:"Test",body:"Body",timestamp:Date.now(),read:false})
            service.history = records
            center.toggleGroup("test")
            root.list = center.children.find(child => child.objectName === "notificationHistoryList")
        }
    }
    Timer {
        interval: 250; running: true
        onTriggered: {
            const first = root.list.itemAtIndex(1)
            const last = root.list.itemAtIndex(12)
            console.log("expansion sample", first ? first.height : -1, last ? last.height : -1, root.list.contentY, root.list.expansionY)
            if (!first || first.height < 60 || (last && last.height > 1)
                || Math.abs(root.list.contentY - root.list.expansionY) > 1)
                console.error("FAIL: top-down expansion with fixed viewport")
            else console.log("PASS: top-down expansion with fixed viewport")
        }
    }
    Timer {
        interval: 800; running: true
        onTriggered: {
            root.list.positionViewAtEnd()
            initialY = root.list.contentY - root.list.originY
            previousY = initialY
            center.toggleGroup("test")
            sampling.start()
        }
    }
    Timer {
        interval: 1000; running: true
        onTriggered: {
            const first = root.list.itemAtIndex(1)
            const middle = root.list.itemAtIndex(6)
            const last = root.list.itemAtIndex(12)
            if (!first || first.height < 60 || !middle || middle.height < 60 || (last && last.height > 1))
                console.error("FAIL: bottom-up collapse retains earlier notifications")
            else console.log("PASS: bottom-up collapse retains earlier notifications")
        }
    }
    Timer {
        id: sampling; interval: 16; repeat: true
        onTriggered: {
            maxStep = Math.max(maxStep, Math.abs(root.list.contentY - root.list.originY - previousY))
            previousY = root.list.contentY - root.list.originY
            samples++
        }
    }
    Timer {
        interval: 2000; running: true
        onTriggered: {
            console.log("scroll recovery", initialY, root.list.contentY - root.list.originY, "max frame step", maxStep, "samples", samples)
            if (initialY < 100 || samples < 10 || Math.abs(root.list.contentY - root.list.originY) > 1 || maxStep > initialY * 0.3 || service.unreadCount !== 12) console.error("FAIL: scroll recovery")
            else console.log("PASS: smooth scroll recovery")
            Qt.quit()
        }
    }
}
