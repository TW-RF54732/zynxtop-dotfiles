pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Scope {
    id: root

    property int defaultTimeout: 16000
    property int historyLimit: 500
    property string historyPath: Quickshell.stateDir + "/notification-history.json"
    property int historySerial: 0
    property var entries: []
    readonly property var notifications: entries.map(entry => entry.notification)
    property var history: []
    property bool historyLoaded: false
    readonly property int unreadCount: history.filter(record => !record.read).length

    FileView {
        id: historyFile
        path: root.historyPath
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    function loadHistory() {
        if (historyLoaded) return
        try {
            const data = JSON.parse(historyFile.text() || "{}")
            history = (Array.isArray(data.records) ? data.records : []).filter(record =>
                record && typeof record.key === "string" && Number.isFinite(record.timestamp)
                && typeof record.summary === "string" && typeof record.body === "string")
                .slice(0, Math.max(0, historyLimit))
        } catch (error) {
            history = []
        }
        historyLoaded = true
    }

    function storeHistory(records) {
        history = records
        historyFile.setText(JSON.stringify({version: 1, records: history}))
    }

    Component.onCompleted: loadHistory()

    function saveNotification(notification, previous) {
        loadHistory()
        if (notification.transient) return ""
        const carried = notification.lastGeneration && !previous
            ? history.find(record => record.sourceId === notification.id
                && record.appName === (notification.appName || "通知")
                && record.summary === (notification.summary || ""))
            : null
        const key = previous?.historyKey || carried?.key
            || Date.now() + "-" + notification.id + "-" + (++historySerial)
        const record = {
            key: key,
            sourceId: notification.id,
            appName: notification.appName || "通知",
            appIcon: notification.appIcon || "",
            source: notification.desktopEntry || notification.appName || "通知",
            summary: notification.summary || "",
            body: notification.body || "",
            urgency: notification.urgency,
            timestamp: carried ? carried.timestamp : Date.now(),
            read: carried ? carried.read : false
        }
        storeHistory([record].concat(history.filter(item => item.key !== key))
            .slice(0, Math.max(0, historyLimit)))
        return key
    }

    function markRead(key) {
        markRecordsRead([key])
    }

    function markRecordsRead(keys) {
        storeHistory(history.map(record => keys.includes(record.key)
            ? Object.assign({}, record, {read: true}) : record))
    }

    function markAllRead() {
        storeHistory(history.map(record => Object.assign({}, record, {read: true})))
    }

    function deleteHistory(key) {
        deleteHistories([key])
    }

    function deleteHistories(keys) {
        storeHistory(history.filter(record => !keys.includes(record.key)))
    }

    function clearHistory() { storeHistory([]) }

    function receive(notification) {
        notification.tracked = true
        const previous = entries.find(entry => entry.notification.id === notification.id)
        const historyKey = saveNotification(notification, previous)
        const timeout = notification.expireTimeout
        const duration = timeout < 0
            ? (notification.urgency === NotificationUrgency.Critical ? 0 : defaultTimeout)
            : timeout
        entries = entries.filter(entry => entry.notification.id !== notification.id).concat([{
            notification: notification,
            historyKey: historyKey,
            deadline: duration > 0 ? Date.now() + duration : 0
        }])
    }

    function remove(id) {
        entries = entries.filter(entry => entry.notification.id !== id)
    }

    function activate(notification) {
        const action = notification.actions.find(action => action.identifier === "default")
        if (action)
            action.invoke()
        else
            notification.dismiss()
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        onNotification: notification => root.receive(notification)
    }

    Instantiator {
        model: server.trackedNotifications
        delegate: Connections {
            required property var modelData
            target: modelData
            function onClosed(reason) { root.remove(modelData.id) }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.entries.length > 0
        onTriggered: {
            const now = Date.now()
            for (const entry of root.entries.slice()) {
                if (entry.deadline > 0 && entry.deadline <= now)
                    entry.notification.expire()
            }
        }
    }
}
