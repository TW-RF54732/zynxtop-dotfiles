pragma ComponentBehavior: Bound
import QtQuick
import "../components"

Item {
    id: root
    required property var theme
    required property var group
    property bool expanded: false
    property string expandedKey: ""
    readonly property bool grouped: group.records.length > 1
    readonly property real headerHeight: header.height
    readonly property real fullContentHeight: messages.height
    property real revealHeight: 0
    function animateReveal() {
        const current = revealHeight
        revealAnimation.stop()
        revealAnimation.from = current
        revealAnimation.to = expanded && grouped ? fullContentHeight : 0
        revealAnimation.start()
    }
    onExpandedChanged: animateReveal()
    onGroupedChanged: animateReveal()
    onFullContentHeightChanged: {
        if (!expanded || !grouped) return
        // A detail row already animates its own height. Once the dropdown is
        // open, track it directly instead of adding a second trailing animation.
        if (revealAnimation.running) animateReveal()
        else revealHeight = fullContentHeight
    }
    Component.onCompleted: revealHeight = expanded && grouped ? fullContentHeight : 0
    signal toggleRequested()
    signal deleteRequested()
    signal recordOpened(var record)
    signal recordClosed(var record)
    objectName: "notificationBlock:" + group.key
    height: header.height + revealHeight
    NumberAnimation {
        id: revealAnimation
        target: root
        property: "revealHeight"
        duration: root.theme.notifications.historyExpandDuration
        easing.type: Easing.InOutCubic
    }
    Rectangle {
        anchors.fill: parent
        radius: root.theme.geometry.cornerRadius
        color: "transparent"
        border.width: 1
        border.color: root.theme.colors.separator
    }
    NotificationHistoryRow {
        id: header
        objectName: "notificationHeader:" + root.group.key
        width: parent.width
        record: root.grouped ? Object.assign({}, root.group.records[0], {
            appName: (root.group.records[0].appName || "通知") + " · " + root.group.records.length + " 則"
        }) : root.group.records[0]
        theme: root.theme
        controlsWidth: root.grouped ? 66 : 32
        expanded: !root.grouped && root.expandedKey === record.key
        onOpenRequested: {
            if (root.grouped) root.toggleRequested()
            else root.recordOpened(root.group.records[0])
        }
        onCloseRequested: {
            if (root.grouped) {
                if (root.expanded) root.toggleRequested()
            } else root.recordClosed(root.group.records[0])
        }
    }
    Item {
        id: reveal
        objectName: "notificationReveal:" + root.group.key
        y: header.height
        width: parent.width
        height: root.revealHeight
        clip: true
        visible: height > 0
        enabled: root.expanded
        // Children keep their natural positions. Only this shared viewport
        // grows downward or rolls upward, including when reversing mid-flight.
        Column {
            id: messages
            width: parent.width
            Repeater {
                model: root.group.records
                Column {
                    id: message
                    required property var modelData
                    width: messages.width
                    height: separator.height + face.height
                    Rectangle {
                        id: separator
                        x: 44; width: Math.max(0, parent.width - x - 8); height: 1
                        color: root.theme.colors.separator
                    }
                    NotificationHistoryRow {
                        id: face
                        width: parent.width
                        theme: root.theme
                        record: message.modelData
                        expanded: root.expandedKey === record.key
                        showDate: true
                        onOpenRequested: root.recordOpened(record)
                        onCloseRequested: root.recordClosed(record)
                    }
                }
            }
        }
    }
    Item {
        x: parent.width - 66; y: 2; width: 30; height: 28
        visible: root.grouped
        Canvas {
            anchors.centerIn: parent
            width: 16; height: 16
            rotation: root.expanded ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: root.theme.notifications.historyExpandDuration; easing.type: Easing.InOutCubic } }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = root.theme.colors.textSecondary
                ctx.lineWidth = 1.5
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath(); ctx.moveTo(4, 6); ctx.lineTo(8, 10); ctx.lineTo(12, 6); ctx.stroke()
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleRequested()
            Accessible.role: Accessible.Button
            Accessible.name: root.expanded ? "收合此來源通知" : "展開此來源通知"
        }
    }
    TextButton {
        objectName: "deleteNotificationGroup:" + root.group.key
        theme: root.theme
        text: "×"
        x: parent.width - 34; y: 2
        width: 30; height: 28
        Accessible.role: Accessible.Button
        Accessible.name: "刪除此區塊的未讀通知"
        onClicked: root.deleteRequested()
    }
}
