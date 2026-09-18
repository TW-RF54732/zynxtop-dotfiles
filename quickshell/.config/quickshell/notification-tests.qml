import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "services"
import "notifications"
import "dashboard"

ShellRoot {
    id: root
    property int failures: 0
    property int realStage: 0
    property var preservedCard: null
    property real preservedStartX: 0
    property real preservedTargetX: 0
    function check(value, message) {
        if (!value) { failures++; console.error("FAIL: " + message) }
    }
    function checkSegments(message) {
        let right = -Infinity
        let valid = true
        for (const notification of strip.visibleNotifications) {
            const card = strip.itemForNotification(notification.id)
            const left = card.x + (1 - card.opacity) * (strip.screenRight - card.x)
            if (left < right - 0.1) valid = false
            right = left + card.width
        }
        check(valid, message)
    }
    function notification(id) {
        return {id: id, summary: "Notification " + id, body: "Body", appName: "Test",
            appIcon: "", tracked: false, urgency: NotificationUrgency.Normal,
            expireTimeout: 0, actions: [], dismiss: () => {}, expire: () => {}}
    }
    Style { id: style }
    NotificationService { id: service }
    Window {
        width: 552; height: 300; visible: true; color: "#181818"
        NotificationCenter { id: center; theme: style; notifications: service; anchors.fill: parent; anchors.margins: 16 }
    }
    Window {
        width: 600; height: 240
        visible: true
        color: "#181818"
        NotificationStrip { id: strip; theme: style; width: style.notifications.cardWidth + style.notifications.stackStep * 3; height: style.topBar.height }
        NotificationStrip { id: emptyBodyStrip; theme: style; y: 180; width: 360; height: style.topBar.height }
    }
    Timer {
        interval: 100; running: true
        onTriggered: {
            if (Quickshell.env("NOTIFICATION_HISTORY_RELOAD") === "1") {
                root.check(service.history.length === 2 && service.unreadCount === 1,
                    "history and read state survive a new shell process")
                root.check(service.history.every(record => record.summary === "Real notification"
                    && record.body === "Body"), "persisted history contains text snapshots")
                console.log(root.failures ? "FAIL: notification history reload" : "PASS: notification history reload")
                Qt.quit()
                return
            }
            service.clearHistory()
            root.check(!strip.visible && strip.occupiedWidth === 0, "empty strip is hidden")
            strip.notifications = [root.notification(1)]
            root.check(strip.visibleCount === 1 && strip.hiddenCount === 0
                && strip.selectedNotification.id === 1, "one notification expands")
            strip.notifications = Array.from({length: 4}, (_, i) => root.notification(i + 1))
            root.check(strip.visibleCount === 4 && strip.hiddenCount === 0,
                "icons stack until the lane fills")
            strip.notifications = Array.from({length: 8}, (_, i) => root.notification(i + 1))
            root.check(strip.hiddenCount === 5 && strip.visibleCount === 3,
                "overflow replaces oldest icons with +5")
            root.check(strip.occupiedWidth <= strip.width
                && strip.visibleNotifications[2].id === 8, "latest title stays on the right within lane")
            const originalOrder = strip.visibleNotifications.map(notification => notification.id).join(",")
            strip.hoverNotification(strip.visibleNotifications[1])
            root.check(strip.expandedIndex === 1 && strip.expandedNotification.id === 7,
                "hover expands the middle notification in its original slot")
            root.check(strip.visibleNotifications.map(notification => notification.id).join(",") === originalOrder,
                "hover preserves notification order")
            root.check(strip.occupiedWidth <= strip.width && strip.hiddenCount === 5,
                "hover preserves the lane width and overflow count")
            strip.clearHover()
            root.check(strip.expandedNotification.id === 8,
                "leaving hover returns expansion to latest notification")
            strip.selectedId = 1
            root.check(strip.selectedNotification.id === 1 && strip.hiddenCount === 5,
                "hidden notifications can be selected without losing count")
            strip.notifications = strip.notifications.slice(1).concat([root.notification(9)])
            root.check(strip.selectedNotification.id === 9,
                "new notification restores latest title even when total count stays the same")
            strip.width = 180
            root.check(strip.occupiedWidth <= strip.width && strip.cardWidth > 0,
                "narrow lane reduces title width without overlapping bar")
            strip.width = style.notifications.cardWidth + style.notifications.stackStep * 3
            strip.notifications = Array.from({length: 1000}, (_, i) => root.notification(i + 1))
            root.check(strip.occupiedWidth <= strip.width && strip.hiddenCount + strip.visibleCount === 1000,
                "large overflow counts fit and count every notification")

            const first = root.notification(1)
            service.receive(first)
            root.check(first.tracked && service.entries[0].deadline === 0, "zero timeout stays until closed")
            root.check(service.history.length === 1 && service.unreadCount === 1
                && service.history[0].body === first.body,
                "receiving saves an unread text snapshot")
            const second = root.notification(2)
            second.expireTimeout = -1
            service.receive(second)
            root.check(service.entries[1].deadline > Date.now(), "default timeout sets a deadline")
            const timed = root.notification(4)
            timed.expireTimeout = 2000
            service.receive(timed)
            root.check(service.entries[2].deadline - Date.now() > 1900,
                "client timeout uses the installed API's milliseconds")
            service.remove(4)
            service.receive(first)
            root.check(service.notifications.length === 2 && service.notifications[1].id === 1,
                "replacement moves to latest without increasing count")
            root.check(service.history.length === 3 && service.history[0].sourceId === 1,
                "replacement updates the same history record")
            service.remove(1)
            root.check(service.notifications.length === 1 && service.notifications[0].id === 2,
                "closing removes only the corresponding notification")
            root.check(service.history.length === 3, "closing keeps the notification history")
            root.check(center.records.length === 3 && center.groups.length === 1 && center.rows.length === 1,
                "same-source unread notifications collapse into one stack")
            center.toggleGroup(center.groups[0].key)
            root.check(center.rows.length === 4 && center.rows[1].key === service.history[0].key,
                "opening a source stack reveals individual notifications newest first")
            center.toggleRecord(service.history[0])
            root.check(!service.history[0].read && center.records.length === 3,
                "viewing detail does not remove a message before reading finishes")
            center.toggleRecord(service.history[0])
            root.check(service.history[0].read && service.unreadCount === 2
                && center.records.length === 2 && center.expandedKey === "",
                "closing a viewed notification automatically marks it read and removes it")
            const other = root.notification(22)
            other.appName = "Other"
            other.desktopEntry = "other.desktop"
            service.receive(other)
            const otherKey = service.history[0].key
            root.check(center.groups.length === 2, "different sources remain separate stacks")
            const testGroup = center.rows.find(row => row.isGroupHeader && row.groupKey === "test")
            center.markRowRead(testGroup)
            root.check(service.unreadCount === 1 && center.groups.length === 1
                && center.records[0].appName === "Other", "marking a source read preserves other unread sources")
            service.markAllRead()
            root.check(service.unreadCount === 0 && center.records.length === 0 && center.rows.length === 0,
                "mark all read clears the unread-only center")
            service.deleteHistory(otherKey)
            service.remove(22)
            service.deleteHistory(service.history[0].key)
            root.check(service.history.length === 2 && service.notifications.length === 1,
                "deleting a history record leaves live popups alone")
            const critical = root.notification(3)
            critical.urgency = NotificationUrgency.Critical
            critical.expireTimeout = -1
            service.receive(critical)
            root.check(service.entries[1].deadline === 0, "critical notification does not auto-expire")
            const transient = root.notification(21)
            transient.transient = true
            const beforeTransient = service.history.length
            service.receive(transient)
            root.check(service.history.length === beforeTransient, "transient notifications are not archived")
            service.historyLimit = 2
            service.receive(root.notification(91))
            service.receive(root.notification(92))
            root.check(service.history.length === 2 && service.history[0].sourceId === 92
                && service.history[1].sourceId === 91, "history retains newest records within limit")
            service.historyLimit = 500
            service.markRead(service.history[0].key)
            const carriedKey = service.history[0].key
            service.entries = []
            const carried = root.notification(92)
            carried.lastGeneration = true
            service.receive(carried)
            root.check(service.history.length === 2 && service.history[0].key === carriedKey
                && service.history[0].read, "hot reload preserves carried notification identity and read state")
            service.clearHistory()
            root.check(service.history.length === 0 && service.notifications.length > 0,
                "clear history preserves active notifications")
            service.entries = []
            const records = Array.from({length: 4}, (_, i) => root.notification(i + 1))
            records[1].body = "詳細訊息與很多內容 ".repeat(200) + "\nExtra line".repeat(30)
            strip.notifications = records
            strip.hoverNotification(strip.notifications[1])
            const blank = root.notification(20)
            blank.body = ""
            emptyBodyStrip.notifications = [blank]
            emptyBodyStrip.hoverNotification(blank)
            hoverSettled.restart()
            sender.running = true
        }
    }
    Timer {
        id: hoverSettled
        interval: style.notifications.expandDuration + 60
        onTriggered: {
            root.checkSegments("hovered card backgrounds occupy separate segments")
            root.check(strip.expandedNotification.id === 2
                && strip.cardOffset(2) > strip.step * 2,
                "middle card opens horizontally and pushes following icons right")
            root.check(strip.notificationAt(strip.cardOffset(1) + 10).id === 2,
                "animated hover hit testing selects the expanded middle card")
            root.check(strip.cardOffset(3) + strip.step <= strip.occupiedWidth,
                "last collapsed icon stays within the reserved width")
            const detailCard = strip.itemForNotification(2)
            root.check(detailCard.height > strip.height
                && detailCard.height <= strip.height + style.notifications.detailMaxHeight,
                "hover expands long body content within the maximum height")
            root.check(strip.itemForNotification(1).height === strip.height
                && strip.itemForNotification(4).height === strip.height,
                "only hovered card grows vertically")
            root.check(Math.abs(strip.surfaceHeight - detailCard.height) < 0.1
                && strip.detailBounds.width > 0,
                "viewport and desktop input bounds include the expanded details")
            root.check(emptyBodyStrip.itemForNotification(20).height === emptyBodyStrip.height,
                "empty body stays as a single header row on hover")
            strip.clearHover()
            hoverClosed.restart()
        }
    }
    Timer {
        id: hoverClosed
        interval: style.notifications.expandDuration + 60
        onTriggered: {
            root.check(strip.expandedNotification.id === 4
                && Math.abs(strip.cardOffset(3) - strip.step * 3) < 0.1,
                "leaving hover contracts older cards and opens newest in place")
            root.check(strip.surfaceHeight === strip.height
                && strip.itemForNotification(2).height === strip.height,
                "leaving hover collapses details and restores compact input bounds")
            root.preservedCard = strip.itemForNotification(4)
            root.preservedStartX = root.preservedCard.x
            strip.notifications = strip.notifications.concat([root.notification(5)])
            root.preservedTargetX = strip.layoutOrigin + strip.counterWidth + strip.cardOffset(1)
            root.check(strip.itemForNotification(4) === root.preservedCard,
                "incoming notification preserves existing card instances")
            const incoming = strip.itemForNotification(5)
            const start = incoming.x + (1 - incoming.opacity) * (strip.screenRight - incoming.x)
            root.check(start >= strip.screenRight - 0.1 && strip.screenRight > strip.width,
                "popup starts beyond the actual screen edge including right margin")
            popupInFlight.restart()
        }
    }
    Timer {
        id: popupInFlight
        interval: 80
        onTriggered: {
            const incoming = strip.itemForNotification(5)
            root.check(incoming && incoming.opacity > 0 && incoming.opacity < 1,
                "new notification slides and fades through an intermediate state")
            root.check(root.preservedCard.opacity === 1,
                "existing card does not replay the popup animation")
            root.check(root.preservedCard.x < root.preservedStartX
                && root.preservedCard.x > root.preservedTargetX,
                "pushed notification slides through an intermediate position")
            root.checkSegments("sliding notification backgrounds never overlap")
            popupSettled.restart()
        }
    }
    Timer {
        id: popupSettled
        interval: 360
        onTriggered: {
            root.checkSegments("settled notification backgrounds never overlap")
            root.check(strip.itemForNotification(5).opacity === 1,
                "incoming popup settles fully visible")
            root.check(Math.abs(root.preservedCard.x - root.preservedTargetX) < 0.1,
                "pushed notification settles at its new slot")
        }
    }
    Process {
        id: sender
        command: ["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
            "--object-path", "/org/freedesktop/Notifications", "--method",
            "org.freedesktop.Notifications.Notify", "Test", "0", "", "Real notification",
            "Body", "[]", "{}", root.realStage === 0 ? "0" : "500"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.check(exitCode === 0, "real D-Bus notification call succeeds")
            received.restart()
        }
    }
    Timer {
        id: received
        interval: 100
        onTriggered: {
            root.check(service.notifications.length === 1, "real notification is tracked")
            if (root.realStage === 0) {
                if (service.notifications.length)
                    service.notifications[0].dismiss()
                root.check(service.notifications.length === 0, "real close signal removes notification")
                root.check(service.history.length === 1, "real dismissed notification remains in history")
                service.markRead(service.history[0].key)
                root.realStage = 1
                sender.running = true
            } else {
                expired.restart()
            }
        }
    }
    Timer {
        id: expired
        interval: style.notifications.expandDuration * 2 + style.notifications.slideDuration + 500
        onTriggered: {
            root.check(service.notifications.length === 0, "real timeout expires and removes notification")
            root.check(service.history.length === 2 && service.unreadCount === 1,
                "expired and dismissed notifications stay in history with read state")
            console.log(root.failures ? "FAIL: notification checks" : "PASS: notification checks")
            Qt.quit()
        }
    }
}
