pragma ComponentBehavior: Bound
import QtQuick
import "../app"
import "../sidebar/Calendar.js" as Calendar

// Week view: day header, all-day strip and a scrollable 24-hour grid of seven day columns.
// Events are tinted by calendar source. Press on an empty slot (drag to size it) requests a
// new event; clicking an event activates it. Rects passed out are in this item's coordinates.
Item {
    id: root
    required property var theme
    required property string weekStart
    required property string todayKey
    property int nowMinute: 0
    property var eventsByDay: ({})
    property string selectedKey: ""
    // Pending new event drawn dashed: {date, startMin, endMin, allDay, title}.
    property var ghost: null
    readonly property var days: [0, 1, 2, 3, 4, 5, 6].map(index => Calendar.addDays(weekStart, index))
    readonly property int hourHeight: theme.calendarWindow.hourHeight
    readonly property int gutter: theme.calendarWindow.gutterWidth
    readonly property int snap: theme.calendarWindow.snapMinutes
    readonly property real columnWidth: (width - gutter) / 7
    readonly property int contentTop: 6
    readonly property int allDayCount: Math.max(1, ...days.map(day => (eventsByDay[day] || []).filter(event => event.allDay).length
        + (ghost && ghost.allDay && ghost.date === day ? 1 : 0)))
    signal eventActivated(var event, rect rect)
    signal slotRequested(string date, int startMin, int endMin, bool allDay, rect rect)

    function minuteY(minute) { return minute / 60 * hourHeight; }
    function rectFor(date, startMin, endMin, allDay) {
        const index = days.indexOf(date);
        const x = gutter + Math.max(0, index) * columnWidth;
        if (allDay || index < 0) return Qt.rect(x, allDayRow.y, columnWidth, allDayRow.height);
        const top = flick.y + contentTop + minuteY(startMin) - flick.contentY;
        return Qt.rect(x, top, columnWidth, Math.max(16, minuteY(endMin - startMin)));
    }
    function scrollTo(target, animated) {
        const bounded = Math.max(0, Math.min(flick.contentHeight - flick.height, target));
        scrollAnimation.stop();
        if (!animated) { flick.contentY = bounded; return; }
        scrollAnimation.to = bounded;
        scrollAnimation.start();
    }
    // Opening position: the now line (today's week) in the upper third, else 08:00.
    function scrollToStart() {
        const today = days.indexOf(todayKey) >= 0;
        scrollTo(today ? minuteY(nowMinute) - flick.height / 3 : minuteY(8 * 60), false);
    }
    // Scrolls just enough to show [startMin, endMin].
    function reveal(startMin, endMin) {
        const top = minuteY(startMin) + contentTop - 12;
        const bottom = minuteY(endMin) + contentTop + 12;
        if (top < flick.contentY) scrollTo(top, false);
        else if (bottom > flick.contentY + flick.height) scrollTo(Math.min(top, bottom - flick.height), false);
    }

    function activate(block) {
        const point = block.mapToItem(root, 0, 0);
        eventActivated(block.event, Qt.rect(point.x, point.y, block.width, block.height));
    }

    // ---- day header ----
    Item {
        id: header
        width: parent.width
        height: 44
        Repeater {
            model: root.days
            Row {
                id: dayHead
                required property string modelData
                required property int index
                readonly property bool today: modelData === root.todayKey
                x: root.gutter + index * root.columnWidth + (root.columnWidth - width) / 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                UiText {
                    theme: root.theme
                    anchors.verticalCenter: parent.verticalCenter
                    text: Calendar.weekday(dayHead.modelData)
                    color: dayHead.today ? root.theme.colors.textPrimary : root.theme.colors.textMuted
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26; height: 26
                    radius: 13
                    color: dayHead.today ? root.theme.colors.textPrimary : "transparent"
                    UiText {
                        theme: root.theme
                        anchors.centerIn: parent
                        mono: true
                        text: Calendar.dayOfMonth(dayHead.modelData)
                        font.pixelSize: 14
                        font.bold: dayHead.today
                        color: dayHead.today ? root.theme.app.surface : root.theme.colors.textSecondary
                    }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.theme.app.line }
    }

    // ---- all-day strip ----
    Item {
        id: allDayRow
        y: header.height
        width: parent.width
        height: root.allDayCount * 24 + 6
        UiText {
            theme: root.theme
            width: root.gutter - 10
            y: 7
            horizontalAlignment: Text.AlignRight
            text: "全天"
            font.pixelSize: 11
            color: root.theme.colors.textMuted
        }
        Repeater {
            model: root.days
            Item {
                id: allDayColumn
                required property string modelData
                required property int index
                readonly property var items: (root.eventsByDay[modelData] || []).filter(event => event.allDay)
                x: root.gutter + index * root.columnWidth
                width: root.columnWidth
                height: parent.height
                Rectangle { width: 1; height: parent.height; color: root.theme.app.line }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.slotRequested(allDayColumn.modelData, 0, 1440, true,
                        Qt.rect(allDayColumn.x, allDayRow.y, allDayColumn.width, allDayRow.height))
                }
                Column {
                    x: 3; y: 3
                    width: parent.width - 6
                    spacing: 2
                    Repeater {
                        model: allDayColumn.items
                        EventBlock {
                            id: allDayBlock
                            required property var modelData
                            theme: root.theme
                            event: modelData
                            selected: modelData.key === root.selectedKey
                            onActivated: root.activate(allDayBlock)
                            compact: true
                            width: parent.width
                            height: 22
                        }
                    }
                    Item {
                        visible: root.ghost !== null && root.ghost.allDay && root.ghost.date === allDayColumn.modelData
                        width: parent.width
                        height: 22
                        DashedBox { anchors.fill: parent; stroke: root.theme.colors.textPrimary }
                        UiText {
                            theme: root.theme
                            x: 6
                            width: parent.width - 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.ghost && root.ghost.title ? root.ghost.title : "新事項"
                            elide: Text.ElideRight
                            font.pixelSize: 12
                            color: root.theme.colors.textPrimary
                        }
                    }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.theme.app.line }
    }

    // ---- hour grid ----
    Flickable {
        id: flick
        objectName: "calendarWeekScroll"
        y: allDayRow.y + allDayRow.height
        width: parent.width
        height: parent.height - y
        contentWidth: width
        contentHeight: 24 * root.hourHeight + root.contentTop * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        onMovementStarted: scrollAnimation.stop()

        NumberAnimation {
            id: scrollAnimation
            target: flick
            property: "contentY"
            duration: 400
            easing.type: Easing.OutQuint
        }

        Item {
            y: root.contentTop
            width: flick.width
            height: 24 * root.hourHeight

            Repeater {
                model: 25
                Item {
                    id: hour
                    required property int index
                    y: index * root.hourHeight
                    width: parent.width
                    Rectangle {
                        x: root.gutter
                        width: parent.width - root.gutter
                        height: 1
                        color: root.theme.app.line
                    }
                    UiText {
                        theme: root.theme
                        visible: hour.index > 0 && hour.index < 24
                        width: root.gutter - 10
                        y: -height / 2
                        mono: true
                        horizontalAlignment: Text.AlignRight
                        text: Calendar.pad2(hour.index) + ":00"
                        font.pixelSize: 10
                        color: root.theme.colors.textMuted
                    }
                }
            }

            Repeater {
                model: root.days
                Item {
                    id: column
                    required property string modelData
                    required property int index
                    readonly property bool today: modelData === root.todayKey
                    readonly property var blocks: Calendar.layoutDay(root.eventsByDay[modelData] || [])
                    x: root.gutter + index * root.columnWidth
                    width: root.columnWidth
                    height: parent.height

                    Rectangle { anchors.fill: parent; visible: column.today; color: root.theme.app.todayTint }
                    Rectangle { width: 1; height: parent.height; color: root.theme.app.line }

                    // Empty-slot press: a click makes a one-hour event on the half hour,
                    // a drag sizes it in snap steps.
                    MouseArea {
                        id: slot
                        objectName: "calendarSlot" + column.index
                        anchors.fill: parent
                        preventStealing: true
                        property int anchorMinute: -1
                        property int currentMinute: -1
                        readonly property bool dragging: pressed && Math.abs(currentMinute - anchorMinute) > root.snap
                        function minuteAt(y) {
                            return Math.max(0, Math.min(1440, Math.round(y / root.hourHeight * 60 / root.snap) * root.snap));
                        }
                        onPressed: mouse => {
                            anchorMinute = minuteAt(mouse.y);
                            currentMinute = anchorMinute;
                        }
                        onPositionChanged: mouse => currentMinute = minuteAt(mouse.y)
                        onReleased: {
                            let start = Math.min(anchorMinute, currentMinute);
                            let end = Math.max(anchorMinute, currentMinute);
                            if (!dragging) {
                                start = Math.min(23 * 60, Math.floor(anchorMinute / 30) * 30);
                                end = start + 60;
                            }
                            anchorMinute = -1;
                            const point = column.mapToItem(root, 0, root.minuteY(start));
                            root.slotRequested(column.modelData, start, end, false,
                                Qt.rect(point.x, point.y, column.width, root.minuteY(end - start)));
                        }
                    }

                    Repeater {
                        model: column.blocks
                        EventBlock {
                            id: timedBlock
                            required property var modelData
                            theme: root.theme
                            selected: modelData.event.key === root.selectedKey
                            onActivated: root.activate(timedBlock)
                            readonly property real laneWidth: (column.width - 6) / modelData.columns
                            event: modelData.event
                            x: 3 + modelData.column * laneWidth
                            y: root.minuteY(modelData.start) + 1
                            width: laneWidth - 2
                            height: Math.max(18, root.minuteY(modelData.end - modelData.start) - 2)
                            compact: height < 34
                        }
                    }

                    // Drag preview, then the pending new event.
                    Item {
                        id: pendingBox
                        readonly property bool previewing: slot.dragging
                        readonly property bool pending: !previewing && root.ghost !== null && !root.ghost.allDay
                            && root.ghost.date === column.modelData
                        readonly property int startMinute: previewing ? Math.min(slot.anchorMinute, slot.currentMinute)
                            : pending ? root.ghost.startMin : 0
                        readonly property int endMinute: previewing ? Math.max(slot.anchorMinute, slot.currentMinute)
                            : pending ? Math.max(root.ghost.startMin + root.snap, root.ghost.endMin) : 0
                        visible: previewing || pending
                        x: 3
                        y: root.minuteY(startMinute) + 1
                        width: parent.width - 6
                        height: Math.max(18, root.minuteY(endMinute - startMinute) - 2)
                        z: 2
                        Rectangle { anchors.fill: parent; radius: root.theme.app.eventRadius; color: root.theme.app.surface; opacity: 0.6 }
                        DashedBox { anchors.fill: parent; stroke: root.theme.colors.textPrimary }
                        Column {
                            x: 6; y: 3
                            width: parent.width - 10
                            UiText {
                                theme: root.theme
                                width: parent.width
                                text: root.ghost && root.ghost.title && !pendingBox.previewing ? root.ghost.title : "新事項"
                                elide: Text.ElideRight
                                font.pixelSize: 12
                                color: root.theme.colors.textPrimary
                            }
                            UiText {
                                theme: root.theme
                                visible: pendingBox.height >= 34
                                mono: true
                                text: Calendar.formatMinutes(pendingBox.startMinute) + " – " + Calendar.formatMinutes(pendingBox.endMinute)
                                font.pixelSize: 10
                                color: root.theme.colors.textSecondary
                            }
                        }
                    }

                    Item {
                        objectName: "calendarNowLine"
                        visible: column.today
                        y: root.minuteY(root.nowMinute)
                        width: parent.width
                        z: 3
                        Rectangle { y: -0.75; width: parent.width; height: 1.5; color: root.theme.colors.textPrimary }
                        Rectangle { x: -3.5; y: -3.5; width: 7; height: 7; radius: 3.5; color: root.theme.colors.textPrimary }
                    }
                }
            }
        }
    }
}
