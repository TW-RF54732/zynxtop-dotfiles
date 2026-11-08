pragma ComponentBehavior: Bound
import QtQuick
import "../sidebar/Calendar.js" as Calendar

// Card next to the sources list: add an ICS subscription, or show one with sync and remove.
Rectangle {
    id: root
    objectName: "calendarSubscriptionCard"
    required property var theme
    property bool adding: false
    property var subscription: null
    property bool syncing: false
    property string error: ""
    readonly property var item: subscription || ({})
    signal subscribeRequested(string name, string url)
    signal removeRequested(string id)
    signal syncRequested()
    signal cancelRequested()

    function reset() {
        nameField.text = "";
        urlField.text = "";
        Qt.callLater(() => nameField.focusInput());
    }
    function maskUrl(url) {
        const match = /^((?:https?|webcal):\/\/[^\/]+)/i.exec(url || "");
        return match ? match[1] + "/…" : "—";
    }

    width: theme.calendarWindow.editorWidth
    height: (adding ? addBody.implicitHeight : detailBody.implicitHeight) + 32
    radius: theme.app.cardRadius
    color: theme.app.raised
    border.width: 1
    border.color: theme.app.raisedBorder

    MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

    Column {
        id: addBody
        x: 18; y: 16
        width: root.width - 36
        spacing: 12
        visible: root.adding

        UiText {
            theme: root.theme
            text: "加入訂閱"
            font.pixelSize: 17
            font.bold: true
            color: root.theme.colors.textPrimary
        }
        LineField {
            id: nameField
            objectName: "calendarSubscriptionName"
            theme: root.theme
            width: parent.width
            placeholder: "名稱：Google、課表、假日…"
            alwaysUnderline: true
            onAccepted: urlField.focusInput()
        }
        LineField {
            id: urlField
            objectName: "calendarSubscriptionUrl"
            theme: root.theme
            width: parent.width
            mono: true
            pixelSize: 12
            placeholder: "https://… 或 webcal://…"
            alwaysUnderline: true
            onAccepted: if (subscribe.interactive) subscribe.clicked()
        }
        UiText {
            theme: root.theme
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: 11
            lineHeight: 1.25
            color: root.theme.colors.textMuted
            text: "唯讀，由 vdirsyncer 每 30 分鐘同步。Google 日曆請用「設定 → 整合日曆 → iCal 格式的私密網址」。網址只存在本機狀態目錄。"
        }
        UiText {
            theme: root.theme
            width: parent.width
            visible: root.error !== ""
            text: root.error
            wrapMode: Text.Wrap
            font.pixelSize: 12
            color: root.theme.colors.textPrimary
        }
        Rectangle { width: parent.width; height: 1; color: root.theme.app.raisedBorder }
        Row {
            anchors.right: parent.right
            spacing: 10
            UiText {
                theme: root.theme
                anchors.verticalCenter: parent.verticalCenter
                text: "Esc 取消"
                font.pixelSize: 11
                color: root.theme.colors.textMuted
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cancelRequested() }
            }
            AppButton {
                id: subscribe
                theme: root.theme
                primary: true
                text: "訂閱"
                interactive: nameField.text.trim() !== "" && urlField.text.trim() !== ""
                onClicked: root.subscribeRequested(nameField.text.trim(), urlField.text.trim())
            }
        }
    }

    Column {
        id: detailBody
        x: 18; y: 16
        width: root.width - 36
        spacing: 12
        visible: !root.adding

        Row {
            spacing: 10
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 11; height: 11; radius: 3
                color: Calendar.sourceColor(root.item.id || "", root.theme.app.sourceColors)
            }
            UiText {
                theme: root.theme
                width: detailBody.width - 21
                text: root.item.name || ""
                elide: Text.ElideRight
                font.pixelSize: 17
                font.bold: true
                color: root.theme.colors.textPrimary
            }
        }
        Grid {
            columns: 2
            columnSpacing: 14
            rowSpacing: 6
            Repeater {
                model: [
                    "網址", root.maskUrl(root.item.url),
                    "上次同步", root.item.lastSync || "尚未同步",
                    "狀態", root.syncing ? "同步中…" : (root.item.error || "正常")
                ]
                UiText {
                    required property string modelData
                    required property int index
                    theme: root.theme
                    width: index % 2 === 0 ? 56 : detailBody.width - 70
                    text: modelData
                    mono: index === 1 || index === 3
                    wrapMode: index === 5 ? Text.Wrap : Text.NoWrap
                    elide: index === 5 ? Text.ElideNone : Text.ElideRight
                    font.pixelSize: 12
                    color: index % 2 === 0 ? root.theme.colors.textMuted : root.theme.colors.textSecondary
                }
            }
        }
        Rectangle { width: parent.width; height: 1; color: root.theme.app.raisedBorder }
        Item {
            width: parent.width
            height: 30
            AppButton {
                x: -8
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                text: "移除"
                onClicked: root.removeRequested(root.item.id)
            }
            AppButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                primary: true
                text: root.syncing ? "同步中…" : "立即同步"
                interactive: !root.syncing
                onClicked: root.syncRequested()
            }
        }
    }
}
