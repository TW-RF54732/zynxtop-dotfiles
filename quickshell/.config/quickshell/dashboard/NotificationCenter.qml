pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell
import "../components"
import "../services"
import "../notifications"

ColumnLayout {
    id: root
    required property var theme
    required property NotificationService notifications
    property string expandedKey: ""
    property string expandedSource: ""
    property real groupExpansionProgress: 0
    property string animatedSource: ""
    property string closingSource: ""
    property real groupClosingProgress: 0
    onExpandedSourceChanged: {
        const resumeProgress = expandedSource && expandedSource === closingSource ? groupClosingProgress : 0
        groupClosing.stop()
        closingSource = animatedSource
        groupClosingProgress = groupExpansionProgress
        groupOpening.stop()
        animatedSource = expandedSource
        groupExpansionProgress = resumeProgress
        if (closingSource) groupClosing.start()
        if (expandedSource) groupOpening.start()
    }
    NumberAnimation {
        id: groupClosing
        target: root
        property: "groupClosingProgress"
        to: 0
        duration: root.theme.notifications.expandDuration
        easing.type: Easing.InOutCubic
        onFinished: root.closingSource = ""
    }
    NumberAnimation {
        id: groupOpening
        target: root
        property: "groupExpansionProgress"
        to: 1
        duration: root.theme.notifications.expandDuration
        easing.type: Easing.InOutCubic
    }
    readonly property var records: notifications.history.filter(record => !record.read)
    readonly property var groups: {
        const bySource = Object.create(null)
        const result = []
        for (const record of records) {
            const key = sourceKey(record)
            let group = bySource[key]
            if (!group) {
                group = {key: key, records: []}
                bySource[key] = group
                result.push(group)
            }
            group.records.push(record)
        }
        return result
    }
    readonly property var rows: layoutRows(false)
    readonly property var modelRows: layoutRows(true)
    function layoutRows(includeCollapsed) {
        const result = []
        groups.forEach((group, groupIndex) => {
            const latest = group.records[0]
            const common = {groupKey: group.key, groupIndex: groupIndex}
            if (group.records.length === 1) {
                result.push(Object.assign({}, latest, common,
                    {isGroupHeader: false, inGroup: false, groupCount: 1}))
            } else {
                result.push(Object.assign({}, latest, common,
                    {key: "group:" + group.key, isGroupHeader: true, inGroup: false,
                        groupCount: group.records.length}))
                if (includeCollapsed || expandedSource === group.key) {
                    const groupHeight = group.records.reduce((height, record) => height + 68 + (record.body ? 18 : 0), 0)
                    let offset = 0
                    group.records.forEach(record => {
                        result.push(Object.assign({}, record, common,
                            {isGroupHeader: false, inGroup: true, groupCount: 1,
                                groupOffset: offset, groupHeight: groupHeight}))
                        offset += 68 + (record.body ? 18 : 0)
                    })
                }
            }
        })
        return result
    }
    onRecordsChanged: {
        if (!records.some(record => record.key === expandedKey)) expandedKey = ""
        if (!records.some(record => sourceKey(record) === expandedSource)) expandedSource = ""
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
        const opening = expandedSource !== key
        if (opening) historyList.holdExpansionPosition()
        expandedSource = opening ? key : ""
    }
    function keysForRow(entry) {
        const group = groups.find(group => group.key === entry.groupKey)
        return entry.isGroupHeader && group ? group.records.map(record => record.key) : [entry.key]
    }
    function markRowRead(entry) { notifications.markRecordsRead(keysForRow(entry)) }
    function deleteRow(entry) { notifications.deleteHistories(keysForRow(entry)) }

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
            onClicked: { root.expandedKey = ""; root.notifications.clearHistory() }
        }
    }

    ListModel {
        id: historyModel
        dynamicRoles: true
        property var items: root.modelRows
        onItemsChanged: synchronize()
        Component.onCompleted: synchronize()
        function synchronize() {
            historyList.reserveScrollSpace()
            const wanted = items.map(item => item.key)
            for (let i = count - 1; i >= 0; --i) {
                if (!wanted.includes(get(i).entry.key)) remove(i)
            }
            for (let i = 0; i < items.length; ++i) {
                let existing = -1
                for (let j = i; j < count; ++j) {
                    if (get(j).entry.key === items[i].key) { existing = j; break }
                }
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
        // Keep the current viewport legal while rows shrink, then release the
        // temporary space once the animated scroll has reached the new bottom.
        function reserveScrollSpace() {
            scrollRecovery.stop()
            bottomMargin = Math.max(bottomMargin, contentY - originY + height)
        }
        property bool expansionHeld: false
        property real expansionY: 0
        function holdExpansionPosition() {
            cancelFlick()
            expansionY = contentY
            expansionHeld = true
            expansionHold.restart()
        }
        Timer {
            id: expansionHold
            interval: root.theme.notifications.expandDuration + 32
            onTriggered: {
                historyList.expansionHeld = false
                historyList.recoverScrollPosition()
            }
        }
        onContentYChanged: {
            if (expansionHeld && !moving && !dragging && Math.abs(contentY - expansionY) > 0.01) contentY = expansionY
        }
        function recoverScrollPosition() {
            if (moving || dragging || expansionHeld) return
            const bottom = Math.max(originY, originY + contentHeight - height)
            const destination = Math.max(originY, Math.min(contentY, bottom))
            if (Math.abs(contentY - destination) > 0.5) {
                scrollRecovery.stop()
                scrollRecovery.to = destination
                scrollRecovery.start()
            } else if (!scrollRecovery.running) {
                bottomMargin = 0
            }
        }
        onContentHeightChanged: Qt.callLater(recoverScrollPosition)
        onOriginYChanged: Qt.callLater(recoverScrollPosition)
        onMovementStarted: {
            expansionHeld = false
            expansionHold.stop()
            scrollRecovery.stop()
        }
        onMovementEnded: recoverScrollPosition()
        NumberAnimation {
            id: scrollRecovery
            target: historyList
            property: "contentY"
            duration: root.theme.notifications.expandDuration
            easing.type: Easing.OutCubic
            onFinished: historyList.bottomMargin = 0
        }
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: historyModel
        // Keep shrinking rows alive so ListView cannot re-estimate offscreen
        // heights and shift its origin halfway through the collapse.
        cacheBuffer: root.modelRows.length * (root.theme.notifications.historyDetailMaxHeight + 120)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 0
        delegate: Item {
            id: row
            required property var entry
            required property int index
            readonly property bool expanded: !entry.isGroupHeader && root.expandedKey === entry.key
            readonly property bool groupExpanded: entry.isGroupHeader && root.expandedSource === entry.groupKey
            readonly property int inset: 0
            readonly property bool startsDay: !entry.inGroup && (entry.groupIndex === 0
                || !root.groups[entry.groupIndex - 1]
                || root.dayKey(entry.timestamp) !== root.dayKey(root.groups[entry.groupIndex - 1].records[0].timestamp))
            readonly property int headingHeight: startsDay ? 24 : 0
            readonly property int bodyHeight: !entry.body ? 0 : expanded
                ? Math.min(root.theme.notifications.historyDetailMaxHeight, bodyText.implicitHeight) : 18
            property real bodyRevealHeight: bodyHeight
            Behavior on bodyRevealHeight {
                NumberAnimation { duration: root.theme.notifications.expandDuration; easing.type: Easing.InOutCubic }
            }
            readonly property real notificationHeight: 52 + bodyRevealHeight + 12
            readonly property real baseHeight: headingHeight + (entry.isGroupHeader
                ? notificationHeight * stackProgress + 24 * (1 - stackProgress) : notificationHeight)
            readonly property real unfoldingProgress: root.animatedSource === entry.groupKey ? root.groupExpansionProgress
                : root.closingSource === entry.groupKey ? root.groupClosingProgress : 0
            readonly property real stackProgress: entry.isGroupHeader ? 1 - unfoldingProgress : 0
            readonly property real groupProgress: entry.inGroup ? unfoldingProgress : 1
            property real revealProgress: 1
            Behavior on revealProgress {
                NumberAnimation { duration: root.theme.notifications.expandDuration; easing.type: Easing.InOutCubic }
            }
            ListView.onAdd: {
                revealProgress = 0
                Qt.callLater(() => revealProgress = 1)
            }
            ListView.onRemove: {
                ListView.delayRemove = true
                removeAnimation.start()
            }
            SequentialAnimation {
                id: removeAnimation
                NumberAnimation { target: row; property: "revealProgress"; to: 0; duration: root.theme.notifications.expandDuration; easing.type: Easing.InOutCubic }
                PropertyAction { target: row; property: "ListView.delayRemove"; value: false }
            }
            width: historyList.width
            // Reveal a single growing area from the top of the group. Each
            // notification keeps its full size instead of unfolding in place.
            readonly property real groupRevealHeight: !entry.inGroup || groupProgress >= 0.999 ? notificationHeight + 4
                : Math.max(0, Math.min(notificationHeight + 4, entry.groupHeight * groupProgress - entry.groupOffset))
            height: (entry.inGroup ? groupRevealHeight : baseHeight + 20 * stackProgress + 4) * revealProgress
            opacity: revealProgress
            enabled: groupProgress > 0
            clip: true

            Canvas {
                id: stackEdges
                anchors.fill: parent
                opacity: row.stackProgress
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Connections {
                    target: row
                    function onBaseHeightChanged() { stackEdges.requestPaint() }
                    function onEntryChanged() { stackEdges.requestPaint() }
                }
                onPaint: {
                    const context = getContext("2d")
                    context.reset()
                    context.clearRect(0, 0, width, height)
                    context.lineWidth = 1
                    context.lineJoin = "round"
                    const layers = row.entry.groupCount > 2 ? 3 : 2
                    for (let layer = layers - 1; layer >= 0; --layer) {
                        const right = width - 17 + layer * 8 - 0.5
                        const bottom = row.baseHeight - 1 + layer * 8 - 0.5
                        context.strokeStyle = layer === 0 ? "#50616d" : "#40515d"
                        context.beginPath()
                        context.moveTo(right, row.headingHeight + 10 + layer * 8)
                        context.lineTo(right, bottom - 5)
                        context.quadraticCurveTo(right, bottom, right - 5, bottom)
                        context.lineTo(44 + layer * 8, bottom)
                        context.stroke()
                    }
                }
            }

            MonoText {
                theme: root.theme
                text: root.dayLabel(row.entry.timestamp)
                font.pixelSize: 11
                tone: root.theme.colors.textMuted
                visible: row.startsDay
            }
            Item {
                id: notificationFace
                objectName: "notificationFace:" + row.entry.key
                width: parent.width
                height: row.headingHeight + row.notificationHeight
                opacity: row.entry.isGroupHeader ? row.stackProgress : 1
                visible: opacity > 0
                enabled: !row.entry.isGroupHeader || !row.groupExpanded
                NotificationIcon {
                    theme: root.theme
                    x: 12 + row.inset; y: row.headingHeight + 8
                    width: 24; height: 24
                    appIcon: row.entry.appIcon || ""
                    appName: row.entry.appName || ""
                    desktopEntry: row.entry.source || ""
                }
                MonoText {
                    theme: root.theme
                    x: 44 + row.inset; y: row.headingHeight + 2
                    width: Math.max(0, parent.width - x - 60)
                    text: (row.entry.appName || "通知") + (row.entry.isGroupHeader ? " · " + row.entry.groupCount + " 則" : "")
                    font.pixelSize: 11
                    tone: root.theme.colors.textSecondary
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                MonoText {
                    theme: root.theme
                    anchors.right: parent.right
                    anchors.rightMargin: row.entry.isGroupHeader ? 30 : 6
                    y: row.headingHeight + 2
                    text: (row.entry.inGroup ? root.dayLabel(row.entry.timestamp) + " " : "")
                        + Qt.formatDateTime(new Date(row.entry.timestamp), "HH:mm")
                    font.pixelSize: 11
                    tone: root.theme.colors.textMuted
                }
                MonoText {
                    theme: root.theme
                    x: 44 + row.inset; y: row.headingHeight + 22
                    width: Math.max(0, parent.width - x - (row.entry.isGroupHeader ? 30 : 8))
                    text: row.entry.summary || "通知"
                    font.pixelSize: 14
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }
                MouseArea {
                    x: 0; y: row.headingHeight
                    width: parent.width
                    height: 52 + (row.expanded ? 0 : row.bodyHeight)
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) root.markRowRead(row.entry)
                        else if (row.entry.isGroupHeader) root.toggleGroup(row.entry.groupKey)
                        else root.toggleRecord(row.entry)
                    }
                }
                Flickable {
                    id: bodyScroll
                    x: 44 + row.inset; y: row.headingHeight + 52
                    width: Math.max(0, parent.width - x - (row.entry.isGroupHeader ? 30 : 8))
                    height: row.bodyRevealHeight
                    contentWidth: width
                    contentHeight: bodyText.implicitHeight
                    interactive: row.expanded && contentHeight > height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    MonoText {
                        id: bodyText
                        theme: root.theme
                        width: parent.width
                        text: row.entry.body
                        font.pixelSize: 12
                        tone: root.theme.colors.textSecondary
                        textFormat: Text.PlainText
                        wrapMode: row.expanded ? Text.Wrap : Text.NoWrap
                        elide: row.expanded ? Text.ElideNone : Text.ElideRight
                    }
                }
            }
            Item {
                id: collapseControl
                objectName: "collapseControl:" + row.entry.groupKey
                y: row.headingHeight
                width: parent.width
                height: 24
                opacity: row.entry.isGroupHeader ? 1 - row.stackProgress : 0
                visible: opacity > 0
                enabled: row.groupExpanded
                Canvas {
                    x: 12; y: 4; width: 24; height: 16
                    onPaint: {
                        const context = getContext("2d")
                        context.reset()
                        context.strokeStyle = root.theme.colors.textSecondary
                        context.lineWidth = 1.5
                        context.lineCap = "round"
                        context.lineJoin = "round"
                        context.beginPath()
                        context.moveTo(7, 5)
                        context.lineTo(12, 10)
                        context.lineTo(17, 5)
                        context.stroke()
                    }
                }
                Rectangle {
                    x: 44; y: 12
                    width: Math.max(0, parent.width - x)
                    height: 1
                    color: root.theme.colors.separator
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleGroup(row.entry.groupKey)
                    Accessible.name: "收合此來源通知"
                    Accessible.role: Accessible.Button
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                x: 44 + row.inset
                width: Math.max(0, parent.width - x)
                height: 1
                color: root.theme.colors.separator
                visible: !row.entry.isGroupHeader
            }
        }

        MonoText {
            parent: historyList
            theme: root.theme
            anchors.centerIn: parent
            text: "沒有未讀通知"
            tone: root.theme.colors.textMuted
            font.pixelSize: 12
            visible: historyList.count === 0
        }
    }
}
