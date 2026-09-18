pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import "../components"

Item {
    id: root

    required property var theme
    property var notifications: []
    property int selectedId: -1
    property int hoveredId: -1
    property int layoutDuration: theme.notifications.slideDuration
    property real screenRight: width + theme.topBar.sideMargin
    property real detailMaxHeight: theme.notifications.detailMaxHeight
    property int cardRevision: 0
    readonly property var detailBounds: {
        let left = screenRight
        let right = 0
        let extra = 0
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (!card || card.height <= height) continue
            const visualX = card.x + (1 - card.opacity) * (screenRight - card.x)
            left = Math.min(left, visualX)
            right = Math.max(right, visualX + card.width
                + (i < cards.count - 1 ? theme.notifications.overlap : 0))
            extra = Math.max(extra, card.height - height)
        }
        return {left: left, width: Math.max(0, right - left), extra: extra}
    }
    readonly property real surfaceHeight: height + detailBounds.extra
    readonly property var frameGeometry: {
        const revision = cardRevision
        const frames = []
        if (overflowBadge && overflowBadge.visible) {
            frames.push({x: overflowBadge.x, width: overflowBadge.width + theme.notifications.overlap,
                height: height, opacity: 1})
        }
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i)
            if (!card) continue
            frames.push({x: cardVisualLeft(i), width: card.width
                + (i < cards.count - 1 ? theme.notifications.overlap : 0),
                height: card.height, opacity: card.opacity})
        }
        return frames
    }
    signal activated(var notification)
    signal dismissed(var notification)

    function hoverNotification(notification) {
        restoreLatest.stop()
        layoutDuration = theme.notifications.expandDuration
        hoveredId = notification.id
    }
    function clearHover() {
        layoutDuration = theme.notifications.expandDuration
        hoveredId = -1
    }

    function synchronizeCards() {
        const next = visibleNotifications
        for (let i = cardModel.count - 1; i >= 0; --i) {
            if (!next.some(notification => String(notification.id) === cardModel.get(i).key))
                cardModel.remove(i)
        }
        for (let i = 0; i < next.length; ++i) {
            const key = String(next[i].id)
            let existing = -1
            for (let j = i; j < cardModel.count; ++j) {
                if (cardModel.get(j).key === key) { existing = j; break }
            }
            if (existing < 0)
                cardModel.insert(i, {key: key, notification: next[i]})
            else {
                if (existing !== i) cardModel.move(existing, i, 1)
                cardModel.setProperty(i, "notification", next[i])
            }
        }
    }

    function itemForNotification(id) {
        for (let i = 0; i < cardModel.count; ++i) {
            if (cardModel.get(i).key === String(id)) return cards.itemAt(i)
        }
        return null
    }

    ListModel { id: cardModel; dynamicRoles: true }
    onVisibleNotificationsChanged: synchronizeCards()
    Component.onCompleted: synchronizeCards()

    Timer {
        id: restoreLatest
        interval: root.theme.notifications.hoverCloseDelay
        onTriggered: root.clearHover()
    }

    readonly property int count: notifications.length
    readonly property int selectedIndex: {
        const index = notifications.findIndex(notification => notification.id === selectedId)
        return index >= 0 ? index : count - 1
    }
    readonly property var selectedNotification: notifications[selectedIndex] || null
    readonly property int step: theme.notifications.stackStep
    readonly property real counterWidth: Math.max(theme.notifications.iconWidth,
        counterMetrics.advanceWidth + theme.notifications.padding * 2)
    readonly property int capacity: Math.max(1, Math.floor(
        (width - Math.min(theme.notifications.cardWidth, width)) / step) + 1)
    readonly property bool overflowing: count > capacity
    readonly property int visibleCount: overflowing ? Math.max(1, Math.floor(
        (width - Math.min(theme.notifications.cardWidth, Math.max(0, width - counterWidth))
         - counterWidth) / step) + 1) : Math.min(count, capacity)
    readonly property int hiddenCount: Math.max(0, count - visibleCount)
    readonly property real cardWidth: Math.max(0, Math.min(theme.notifications.cardWidth,
        width - (visibleCount - 1) * step - (hiddenCount > 0 ? counterWidth : 0)))
    readonly property var visibleNotifications: {
        const start = Math.max(0, Math.min(count - visibleCount, selectedIndex))
        return notifications.slice(start, start + visibleCount)
    }
    readonly property int expandedIndex: {
        const hovered = visibleNotifications.findIndex(notification => notification.id === hoveredId)
        if (hovered >= 0) return hovered
        return visibleNotifications.findIndex(notification => notification.id === selectedNotification?.id)
    }
    readonly property var expandedNotification: visibleNotifications[expandedIndex] || null

    function cardOffset(index) {
        return index * step + (expandedIndex >= 0 && expandedIndex < index ? cardWidth - step : 0)
    }

    function cardVisualLeft(index) {
        // Track delegate creation as well as animation progress.
        const revision = cardRevision
        const card = cards.itemAt(index)
        return card ? card.x + (1 - card.opacity) * (screenRight - card.x) : screenRight
    }

    function notificationAt(position) {
        for (let i = visibleCount - 1; i >= 0; --i) {
            const card = cards.itemAt(i)
            if (!card) continue
            const left = card.x - layoutOrigin + (1 - card.opacity) * (screenRight - card.x)
            if (position >= left && position < left + card.width)
                return visibleNotifications[i]
        }
        return null
    }

    readonly property real occupiedWidth: count > 0
        ? cardWidth + (visibleCount - 1) * step + (hiddenCount > 0 ? counterWidth : 0) : 0
    readonly property real layoutOrigin: width - occupiedWidth

    implicitHeight: theme.topBar.height
    visible: count > 0 && width > 0
    clip: false
    onNotificationsChanged: {
        layoutDuration = theme.notifications.slideDuration
        selectedId = -1
        hoveredId = -1
    }

    TextMetrics {
        id: counterMetrics
        font.family: root.theme.typography.family
        font.pixelSize: root.theme.topBar.textSize
        // Reserve for the widest possible count without depending on the layout result.
        text: "+" + Math.max(0, root.count - 1)
    }

    Item {
        // Clip at the actual screen edge, allowing the popup to cross the right margin.
        width: root.screenRight
        height: root.surfaceHeight
        clip: true

        Canvas {
            id: stackCanvas
            width: parent.width
            height: parent.height
            property var frames: root.frameGeometry
            property color surfaceColor: root.theme.colors.topBarSurface
            property color edgeColor: root.theme.colors.separator
            opacity: surfaceColor.a
            antialiasing: true
            onFramesChanged: requestPaint()
            onSurfaceColorChanged: requestPaint()
            onEdgeColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            function roundedFrame(context, x, y, width, height, radius) {
                const r = Math.min(radius, width / 2, height / 2)
                context.beginPath()
                context.moveTo(x + r, y)
                context.lineTo(x + width - r, y)
                context.quadraticCurveTo(x + width, y, x + width, y + r)
                context.lineTo(x + width, y + height - r)
                context.quadraticCurveTo(x + width, y + height, x + width - r, y + height)
                context.lineTo(x + r, y + height)
                context.quadraticCurveTo(x, y + height, x, y + height - r)
                context.lineTo(x, y + r)
                context.quadraticCurveTo(x, y, x + r, y)
                context.closePath()
            }

            onPaint: {
                const context = getContext("2d")
                context.reset()
                context.clearRect(0, 0, width, height)
                // Opaque fills cover previous card edges; apply transparency once to the canvas.
                context.fillStyle = Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 1)
                context.strokeStyle = edgeColor
                const stroke = root.theme.topBar.dividerWidth
                context.lineWidth = stroke
                for (const frame of frames) {
                    if (frame.width <= stroke || frame.opacity <= 0) continue
                    context.globalAlpha = frame.opacity
                    roundedFrame(context, frame.x + stroke / 2, stroke / 2,
                        frame.width - stroke, frame.height - stroke, root.theme.topBar.radius)
                    context.fill()
                    context.stroke()
                }
            }
        }

        GlassFrame {
            id: overflowBadge
            x: root.layoutOrigin
            Behavior on x {
                NumberAnimation {
                    duration: root.theme.notifications.slideDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
                }
            }
            width: Math.max(0, Math.min(root.counterWidth, root.cardVisualLeft(0) - x))
            height: root.height
            theme: root.theme
            radius: root.theme.topBar.radius
            color: "transparent"
            border.width: 0
            visible: root.hiddenCount > 0

            MonoText {
                theme: root.theme
                width: root.counterWidth
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: root.theme.topBar.textSize
                text: "+" + root.hiddenCount
            }
        }

        Repeater {
            id: cards
            model: cardModel
            onItemAdded: root.cardRevision++
            onItemRemoved: root.cardRevision++
            delegate: GlassFrame {
                id: card
                required property var notification
                readonly property var modelData: notification
                required property int index
                readonly property bool expanded: index === root.expandedIndex
                property real reveal: expanded ? 1 : 0
                property real detailProgress: root.hoveredId === modelData.id && expanded
                    && (modelData.body || "").trim().length > 0 ? 1 : 0
                readonly property real detailHeight: Math.max(0, Math.min(root.detailMaxHeight,
                    bodyText.implicitHeight + root.theme.notifications.padding * 2 + 1))
                Behavior on detailProgress {
                    NumberAnimation {
                        duration: root.theme.notifications.expandDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
                    }
                }
                Behavior on reveal {
                    NumberAnimation {
                        duration: root.theme.notifications.expandDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
                    }
                }
                property real popupProgress: 0
                property bool ready: false
                Component.onCompleted: {
                    ready = true
                    popupProgress = 1
                }
                Behavior on popupProgress {
                    NumberAnimation {
                        duration: root.theme.notifications.slideDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
                    }
                }
                opacity: popupProgress
                transform: Translate { x: (1 - card.popupProgress) * (root.screenRight - card.x) }
                x: root.layoutOrigin + (root.hiddenCount > 0 ? root.counterWidth : 0)
                    + root.cardOffset(index)
                Behavior on x {
                    enabled: card.ready
                    NumberAnimation {
                        duration: root.layoutDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
                    }
                }
                z: index + 1
                // Each card owns one segment, including while neighbouring cards slide.
                width: Math.max(0, Math.min(root.step + (root.cardWidth - root.step) * reveal,
                    index < root.visibleCount - 1
                        ? root.cardVisualLeft(index + 1) - root.cardVisualLeft(index)
                        : root.cardWidth))
                height: root.height + detailHeight * detailProgress
                theme: root.theme
                radius: root.theme.topBar.radius
                color: "transparent"
                border.width: 0

                Image {
                    id: icon
                    x: (root.step - width) / 2
                    y: (root.height - height) / 2
                    width: root.theme.topBar.iconSize
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                    source: {
                        const path = card.modelData.appIcon
                        if (!path) return ""
                        if (path.startsWith("/")) return "file://" + path
                        if (path.includes("://")) return path
                        return Quickshell.iconPath(path)
                    }
                    visible: status === Image.Ready
                }
                MonoText {
                    theme: root.theme
                    width: root.step
                    height: root.height
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "󰂚"
                    visible: !icon.visible
                }
                MonoText {
                    theme: root.theme
                    x: root.step + root.theme.notifications.padding
                    // Keep glyph layout fixed while the card reveals it through clipping.
                    width: Math.max(0, root.cardWidth - x - root.theme.notifications.padding)
                    height: root.height
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: root.theme.topBar.textSize
                    textFormat: Text.PlainText
                    text: card.modelData.summary || card.modelData.body || card.modelData.appName
                    elide: Text.ElideRight
                    opacity: card.reveal
                    visible: opacity > 0
                    transform: Translate { x: (1 - card.reveal) * root.theme.notifications.padding }
                }

                Rectangle {
                    x: root.theme.notifications.padding
                    y: root.height
                    width: Math.max(0, root.cardWidth - x * 2)
                    height: 1
                    color: root.theme.colors.separator
                    opacity: card.detailProgress
                }
                MonoText {
                    id: bodyText
                    theme: root.theme
                    x: root.theme.notifications.padding
                    y: root.height + x + 1
                    width: Math.max(0, root.cardWidth - x * 2)
                    height: Math.max(0, Math.min(implicitHeight,
                        card.detailHeight - root.theme.notifications.padding * 2 - 1))
                    font.pixelSize: root.theme.typography.emptySize
                    tone: root.theme.colors.textSecondary
                    text: card.modelData.body || ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: root.theme.notifications.detailMaxLines
                    elide: Text.ElideRight
                    opacity: card.detailProgress
                    visible: opacity > 0
                    clip: true
                }
                MouseArea {
                    y: root.height
                    width: parent.width
                    height: Math.max(0, parent.height - y)
                    enabled: height > 0
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoverNotification(card.modelData)
                    onExited: restoreLatest.restart()
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) root.dismissed(card.modelData)
                        else root.activated(card.modelData)
                    }
                }
            }
        }

        // One stable hit area avoids hover switching when the cards animate under the cursor.
        MouseArea {
            x: root.layoutOrigin
            width: root.occupiedWidth
            height: root.height
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                restoreLatest.stop()
                const notification = root.notificationAt(mouseX)
                if (notification) root.hoverNotification(notification)
            }
            onPositionChanged: mouse => {
                const notification = root.notificationAt(mouse.x)
                if (notification) root.hoverNotification(notification)
            }
            onExited: restoreLatest.restart()
            onClicked: mouse => {
                const notification = root.notificationAt(mouse.x)
                if (!notification) {
                    if (root.hiddenCount > 0) {
                        root.clearHover()
                        root.selectedId = root.notifications[
                            (root.selectedIndex - 1 + root.count) % root.count].id
                    }
                } else if (mouse.button === Qt.RightButton) {
                    root.dismissed(notification)
                } else {
                    root.activated(notification)
                }
            }
        }
    }
}
