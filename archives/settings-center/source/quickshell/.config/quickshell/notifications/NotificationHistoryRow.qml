pragma ComponentBehavior: Bound
import QtQuick
import "../components"

Item {
    id: root
    required property var theme
    required property var record
    property bool expanded: false
    property real controlsWidth: 0
    property bool showDate: false
    signal openRequested()
    signal closeRequested()
    objectName: "notificationFace:" + record.key
    readonly property real bodyHeight: !record.body ? 0 : expanded
        ? Math.min(theme.notifications.historyDetailMaxHeight, bodyText.implicitHeight) : 18
    property real bodyRevealHeight: bodyHeight
    Behavior on bodyRevealHeight {
        NumberAnimation { duration: root.theme.notifications.historyExpandDuration; easing.type: Easing.InOutCubic }
    }
    implicitHeight: 60 + bodyRevealHeight
    height: implicitHeight
    NotificationIcon {
        theme: root.theme
        x: 10; y: 10; width: 24; height: 24
        appIcon: root.record.appIcon || ""
        appName: root.record.appName || ""
        desktopEntry: root.record.source || ""
    }
    MonoText {
        theme: root.theme
        x: 44; y: 6
        width: Math.max(0, parent.width - x - 8 - root.controlsWidth)
        text: root.record.appName || "通知"
        font.pixelSize: 11
        tone: root.theme.colors.textSecondary
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }
    MonoText {
        theme: root.theme
        x: 44; y: 26
        width: Math.max(0, parent.width - x - timestamp.width - 16)
        text: root.record.summary || "通知"
        font.pixelSize: 14
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }
    MonoText {
        id: timestamp
        theme: root.theme
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: 28
        text: Qt.formatDateTime(new Date(root.record.timestamp), root.showDate ? "MM/dd HH:mm" : "HH:mm")
        font.pixelSize: 10
        tone: root.theme.colors.textMuted
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        gesturePolicy: TapHandler.DragThreshold
        onTapped: (point, button) => {
            if (button === Qt.RightButton) root.closeRequested()
            else root.openRequested()
        }
    }
    Flickable {
        x: 44; y: 50
        width: Math.max(0, parent.width - x - 8)
        height: root.bodyRevealHeight
        contentWidth: width
        contentHeight: bodyText.implicitHeight
        interactive: root.expanded && contentHeight > height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        MonoText {
            id: bodyText
            theme: root.theme
            width: parent.width
            text: root.record.body || ""
            font.pixelSize: 12
            tone: root.theme.colors.textSecondary
            textFormat: Text.PlainText
            wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
            elide: root.expanded ? Text.ElideNone : Text.ElideRight
        }
    }
}
