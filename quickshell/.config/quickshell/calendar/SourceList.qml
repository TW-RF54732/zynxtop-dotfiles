pragma ComponentBehavior: Bound
import QtQuick
import "../app"
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

    SectionLabel {
        theme: root.theme
        text: "日曆"
    }

    Repeater {
        model: root.entries
        ListRow {
            id: row
            required property var modelData
            readonly property var subscription: modelData.subscription
            width: root.width
            theme: root.theme
            text: modelData.name
            detail: subscription && subscription.error ? "錯誤" : ""
            selected: root.selectedId === modelData.id
            clickable: subscription !== null
            textColor: modelData.id === "local" ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
            onClicked: root.subscriptionActivated(modelData.id, row)

            Rectangle {
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 10; height: 10
                radius: 3
                color: Calendar.sourceColor(row.modelData.id, root.theme.app.sourceColors)
            }
        }
    }

    Item { width: 1; height: 6 }

    ListRow {
        id: addRow
        objectName: "calendarAddSubscription"
        width: root.width
        theme: root.theme
        text: "＋ 加入訂閱"
        textX: 8
        muted: true
        selected: root.selectedId === "add"
        onClicked: root.addRequested(addRow)
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
