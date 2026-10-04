pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import "../components"
import "../services"
import "../notifications"

ColumnLayout {
    id: root
    required property var theme
    required property NotificationService notifications
    property string expandedKey: ""
    property string expandedSource: ""
    readonly property var records: notifications.history.filter(record => !record.read)
    readonly property var groups: {
        const bySource = Object.create(null)
        const result = []
        for (const record of records) {
            const key = sourceKey(record)
            if (!bySource[key]) {
                bySource[key] = {key: key, records: []}
                result.push(bySource[key])
            }
            bySource[key].records.push(record)
        }
        return result
    }
    // Logical rows for actions; visual layout uses one stable item per source.
    readonly property var rows: {
        const result = []
        for (const group of groups) {
            const grouped = group.records.length > 1
            result.push(Object.assign({}, group.records[0], {
                key: grouped ? "group:" + group.key : group.records[0].key,
                groupKey: group.key, isGroupHeader: grouped
            }))
            if (grouped && expandedSource === group.key)
                group.records.forEach(record => result.push(Object.assign({}, record, {groupKey: group.key, isGroupHeader: false})))
        }
        return result
    }
    onRecordsChanged: {
        if (!records.some(record => record.key === expandedKey)) expandedKey = ""
        if (records.filter(record => sourceKey(record) === expandedSource).length < 2) expandedSource = ""
    }
    spacing: 8

    function dayKey(timestamp) { return Qt.formatDateTime(new Date(timestamp), "yyyy-MM-dd") }
    function dayLabel(timestamp) {
        const date = new Date(timestamp)
        const today = new Date()
        const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1)
        if (dayKey(timestamp) === dayKey(today.getTime())) return "今天"
        if (dayKey(timestamp) === dayKey(yesterday.getTime())) return "昨天"
        return Qt.formatDateTime(date, date.getFullYear() === today.getFullYear() ? "MM/dd" : "yyyy/MM/dd")
    }
    function sourceKey(record) {
        return String(record.source || record.appName || "通知").trim().toLowerCase().replace(/\.desktop$/, "")
    }
    function toggleRecord(record) {
        historyList.reserveScrollSpace()
        const previous = expandedKey
        expandedKey = previous === record.key ? "" : record.key
        if (previous) notifications.markRead(previous)
    }
    function toggleGroup(key) {
        historyList.reserveScrollSpace()
        const previous = expandedKey
        expandedKey = ""
        if (previous) notifications.markRead(previous)
        expandedSource = expandedSource === key ? "" : key
    }
    function openRecord(record) { if (expandedKey !== record.key) toggleRecord(record) }
    function keysForRow(entry) {
        const group = groups.find(group => group.key === entry.groupKey)
        return entry.isGroupHeader && group ? group.records.map(record => record.key) : [entry.key]
    }
    function markRowRead(entry) {
        historyList.reserveScrollSpace()
        notifications.markRecordsRead(keysForRow(entry))
    }
    function deleteRow(entry) {
        historyList.reserveScrollSpace()
        notifications.deleteHistories(keysForRow(entry))
    }
    function deleteGroup(key) {
        const group = groups.find(group => group.key === key)
        if (!group) return
        historyList.reserveScrollSpace()
        notifications.deleteHistories(group.records.map(record => record.key))
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        MonoText { theme: root.theme; text: "NOTIFICATIONS"; font.pixelSize: 12; tone: root.theme.colors.textSecondary }
        Item { Layout.fillWidth: true }
        TextButton {
            theme: root.theme
            text: "清除"
            implicitWidth: 48; implicitHeight: 28
            interactive: root.notifications.history.length > 0
            onClicked: {
                historyList.reserveScrollSpace()
                root.expandedKey = ""
                root.notifications.clearHistory()
            }
        }
    }

    ListModel {
        id: groupModel
        dynamicRoles: true
        property var items: root.groups
        onItemsChanged: synchronize()
        Component.onCompleted: synchronize()
        function synchronize() {
            historyList.reserveScrollSpace()
            const wanted = items.map(item => item.key)
            for (let i = count - 1; i >= 0; --i)
                if (!wanted.includes(get(i).entry.key)) remove(i)
            for (let i = 0; i < items.length; ++i) {
                let existing = -1
                for (let j = i; j < count; ++j)
                    if (get(j).entry.key === items[i].key) { existing = j; break }
                if (existing < 0) insert(i, {entry: items[i]})
                else {
                    if (existing !== i) move(existing, i, 1)
                    if (JSON.stringify(get(i).entry) !== JSON.stringify(items[i])) setProperty(i, "entry", items[i])
                }
            }
        }
    }

    ListView {
        id: historyList
        objectName: "notificationHistoryList"
        // Prevent ListView's automatic bottom clamp while a block shrinks.
        // Follow the animated content edge once per frame instead of restarting
        // a second scroll animation on every height update.
        function reserveScrollSpace() {
            bottomMargin = Math.max(bottomMargin, contentY - originY + height)
        }
        function recoverScrollPosition() {
            if (moving || dragging) return
            const bottom = Math.max(originY, originY + contentHeight - height)
            contentY = Math.max(originY, Math.min(contentY, bottom))
            bottomMargin = 0
        }
        onContentHeightChanged: Qt.callLater(recoverScrollPosition)
        onOriginYChanged: Qt.callLater(recoverScrollPosition)
        onMovementEnded: recoverScrollPosition()
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: groupModel
        // Keep every source item measured so offscreen heights cannot jump.
        cacheBuffer: root.records.length * (root.theme.notifications.historyDetailMaxHeight + 160)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 0
        delegate: Item {
            id: row
            required property var entry
            required property int index
            objectName: "notificationGroup:" + entry.key
            readonly property bool startsDay: index === 0 || !root.groups[index - 1]
                || root.dayKey(entry.records[0].timestamp) !== root.dayKey(root.groups[index - 1].records[0].timestamp)
            readonly property int headingHeight: startsDay ? 24 : 0
            property real revealProgress: 1
            width: historyList.width
            height: (headingHeight + block.height + 12) * revealProgress
            opacity: revealProgress
            clip: true
            ListView.onRemove: {
                ListView.delayRemove = true
                removal.start()
            }
            SequentialAnimation {
                id: removal
                NumberAnimation { target: row; property: "revealProgress"; to: 0; duration: root.theme.notifications.historyExpandDuration; easing.type: Easing.InOutCubic }
                PropertyAction { target: row; property: "ListView.delayRemove"; value: false }
            }
            MonoText {
                theme: root.theme
                text: root.dayLabel(row.entry.records[0].timestamp)
                font.pixelSize: 11
                tone: root.theme.colors.textMuted
                visible: row.startsDay
            }
            NotificationGroup {
                id: block
                y: row.headingHeight
                width: parent.width
                theme: root.theme
                group: row.entry
                expanded: root.expandedSource === row.entry.key
                expandedKey: root.expandedKey
                onToggleRequested: root.toggleGroup(row.entry.key)
                onDeleteRequested: root.deleteGroup(row.entry.key)
                onRecordOpened: record => root.openRecord(record)
                onRecordClosed: record => root.markRowRead(record)
            }
        }
        MonoText {
            theme: root.theme
            anchors.centerIn: parent
            text: "沒有未讀通知"
            tone: root.theme.colors.textMuted
            font.pixelSize: 12
            visible: root.records.length === 0
        }
    }
}
