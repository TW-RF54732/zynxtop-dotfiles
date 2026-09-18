pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: root

    property int defaultTimeout: 16000
    property var entries: []
    readonly property var notifications: entries.map(entry => entry.notification)

    function receive(notification) {
        notification.tracked = true
        const timeout = notification.expireTimeout
        const duration = timeout < 0
            ? (notification.urgency === NotificationUrgency.Critical ? 0 : defaultTimeout)
            : timeout
        entries = entries.filter(entry => entry.notification.id !== notification.id).concat([{
            notification: notification,
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
