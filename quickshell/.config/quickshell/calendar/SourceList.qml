pragma ComponentBehavior: Bound
import QtQuick
import "../sidebar/Calendar.js" as Calendar

// Calendar sources in the window sidebar: tint swatch, name, error mark. Subscriptions open
// their card on click; subscriptions not synced yet (no vdir) are listed from `subscriptions`.
Column {
    id: root
    required property var theme
    property var calendars: []
    property var subscriptions: []
    property bool syncing: false
    property string selectedId: ""
    readonly property var entries: {
        const list = calendars.map(item => ({id: item.id, name: item.name}));
        if (!list.some(item => item.id === "local")) list.unshift({id: "local", name: "本機"});
        for (const item of subscriptions)
            if (!list.some(entry => entry.id === item.id)) list.push({id: item.id, name: item.name});
        return list.map(entry => Object.assign(entry, {
            subscription: subscriptions.find(item => item.id === entry.id) || null
        }));
    }
    signal subscriptionActivated(string id, Item row)
    signal addRequested(Item row)
    signal syncRequested()

    spacing: 2

    UiText {
        theme: root.theme
        text: "日曆"
        font.pixelSize: 11
        color: root.theme.colors.textMuted
        bottomPadding: 4
    }

    Repeater {
        model: root.entries
        Rectangle {
            id: row
            required property var modelData
            readonly property var subscription: modelData.subscription
            width: root.width
            height: 28
            radius: root.theme.app.eventRadius
            color: (rowMouse.containsMouse && subscription) || root.selectedId === modelData.id
                ? root.theme.app.hover : "transparent"

            Rectangle {
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 10; height: 10
                radius: 3
                color: Calendar.sourceColor(row.modelData.id, root.theme.app.sourceColors)
            }
            UiText {
                theme: root.theme
                x: 26
                width: parent.width - x - errorMark.width - 12
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.name
                elide: Text.ElideRight
                color: row.modelData.id === "local" ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
            }
            UiText {
                id: errorMark
                theme: root.theme
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: row.subscription && row.subscription.error ? "錯誤" : ""
                font.pixelSize: 11
                color: root.theme.colors.textMuted
            }
            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: row.subscription !== null
                cursorShape: Qt.PointingHandCursor
                onClicked: root.subscriptionActivated(row.modelData.id, row)
            }
        }
    }

    Item { width: 1; height: 6 }

    Rectangle {
        id: addRow
        width: root.width
        height: 28
        radius: root.theme.app.eventRadius
        color: addMouse.containsMouse || root.selectedId === "add" ? root.theme.app.hover : "transparent"
        UiText {
            theme: root.theme
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "＋ 加入訂閱"
            color: addMouse.containsMouse ? root.theme.colors.textPrimary : root.theme.colors.textMuted
        }
        MouseArea {
            id: addMouse
            objectName: "calendarAddSubscription"
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.addRequested(addRow)
        }
    }
    UiText {
        theme: root.theme
        x: 8
        topPadding: 2
        visible: root.subscriptions.length > 0
        text: root.syncing ? "同步中…" : "立即同步"
        font.pixelSize: 11
        color: syncMouse.containsMouse ? root.theme.colors.textPrimary : root.theme.colors.textMuted
        MouseArea {
            id: syncMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !root.syncing
            cursorShape: Qt.PointingHandCursor
            onClicked: root.syncRequested()
        }
    }
}
