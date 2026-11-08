pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "Calendar.js" as Calendar

// Right half of the agenda: a scrollable 24-hour day column with a now pointer.
Item {
    id: root
    objectName: "agendaTimeline"
    required property var theme
    property var events: []
    property string selectedKey: ""
    property bool showNow: false
    property int nowMinute: 0
    readonly property int hourHeight: theme.sidebar.hourHeight
    readonly property int labelWidth: 28
    readonly property var allDay: Calendar.sortEvents(events).filter(event => event.allDay)
    readonly property var blocks: Calendar.layoutDay(events)
    readonly property alias nowPointer: pointer
    signal eventActivated(var event)

    function minuteY(minute) { return minute / 60 * hourHeight; }
    // Today: keep the pointer in the upper third. Other days: first timed event, else 08:00.
    function scrollToFocus() {
        let focus = 8 * 60;
        if (showNow) focus = nowMinute;
        else if (blocks.length > 0) focus = blocks[0].start;
        scrollTo(minuteY(focus) - (showNow ? flick.height / 3 : 8), false);
    }
    // Centers a timed event; near the top/bottom it stops at the bound instead.
    function scrollToEvent(event) {
        if (!event || event.allDay) return;
        const item = blocks.find(block => block.event.key === event.key);
        if (!item) return;
        const middle = minuteY((item.start + item.end) / 2) + 4;
        scrollTo(middle - flick.height / 2, true);
    }
    function scrollTo(target, animated) {
        const bounded = Math.max(0, Math.min(flick.contentHeight - flick.height, target));
        scrollAnimation.stop();
        if (!animated) { flick.contentY = bounded; return; }
        flick.cancelFlick();
        scrollAnimation.to = bounded;
        scrollAnimation.start();
    }

    Column {
        id: allDayStrip
        width: parent.width
        spacing: 2
        bottomPadding: root.allDay.length > 0 ? 4 : 0
        Repeater {
            model: root.allDay
            Rectangle {
                id: chip
                required property var modelData
                readonly property bool selected: modelData.key === root.selectedKey
                x: root.labelWidth
                width: allDayStrip.width - root.labelWidth
                height: 20
                radius: root.theme.geometry.cornerRadius
                color: root.theme.colors.frame
                border.width: 1
                border.color: selected ? root.theme.colors.textSecondary : root.theme.colors.frame
                MonoText {
                    theme: root.theme
                    anchors.fill: parent
                    anchors.leftMargin: 6; anchors.rightMargin: 6
                    verticalAlignment: Text.AlignVCenter
                    text: chip.modelData.title
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    tone: chip.selected ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.eventActivated(chip.modelData)
                }
            }
        }
    }

    Flickable {
        id: flick
        objectName: "agendaTimelineScroll"
        anchors.top: allDayStrip.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentWidth: width
        contentHeight: 24 * root.hourHeight + 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        onMovementStarted: scrollAnimation.stop()

        // Fast start, gentle arrival.
        NumberAnimation {
            id: scrollAnimation
            target: flick
            property: "contentY"
            duration: 450
            easing.type: Easing.OutQuint
        }

        Item {
            y: 4
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
                        x: root.labelWidth
                        width: parent.width - root.labelWidth
                        height: 1
                        color: root.theme.colors.separator
                    }
                    MonoText {
                        theme: root.theme
                        visible: hour.index < 24
                        y: -height / 2
                        text: Calendar.pad2(hour.index)
                        font.pixelSize: 10
                        tone: root.theme.colors.textMuted
                    }
                }
            }

            Repeater {
                model: root.blocks
                Rectangle {
                    id: block
                    required property var modelData
                    readonly property var event: modelData.event
                    readonly property bool selected: event.key === root.selectedKey
                    readonly property real columnWidth: (parent.width - root.labelWidth - 4) / modelData.columns
                    x: root.labelWidth + 4 + modelData.column * columnWidth
                    y: root.minuteY(modelData.start) + 1
                    width: columnWidth - 2
                    height: Math.max(14, root.minuteY(modelData.end - modelData.start) - 2)
                    radius: root.theme.geometry.cornerRadius
                    color: root.theme.colors.frame
                    border.width: 1
                    border.color: selected ? root.theme.colors.textSecondary : root.theme.colors.frame
                    clip: true
                    MonoText {
                        theme: root.theme
                        x: 5; y: 2
                        width: parent.width - 8
                        text: block.event.title
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        font.pixelSize: 11
                        tone: block.selected ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.eventActivated(block.event)
                    }
                }
            }

            Item {
                id: pointer
                objectName: "agendaNowPointer"
                visible: root.showNow
                y: root.minuteY(root.nowMinute)
                width: parent.width
                z: 2
                Rectangle {
                    x: root.labelWidth
                    y: -0.5
                    width: parent.width - root.labelWidth
                    height: 1
                    color: root.theme.colors.textPrimary
                }
                Rectangle {
                    x: root.labelWidth - 3
                    y: -3
                    width: 6; height: 6; radius: 3
                    color: root.theme.colors.textPrimary
                }
            }
        }
    }
}
