import QtQuick

// SDDM greeter in the Quickshell app-layer language: sharp wallpaper, one solid card,
// 1px borders, 5px corners, bold title + muted subtitle, one filled primary action.
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#0b0c0f"

    readonly property string uiFont: "Noto Sans CJK TC"
    readonly property string monoFont: "JetBrainsMono Nerd Font Mono"
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#ABB2BF"
    readonly property color textMuted: "#5C6370"
    readonly property color frame: "#282C34"
    readonly property color danger: "#E06C75"
    readonly property int radius: 5
    readonly property int fastDuration: 140

    property bool failed: false
    property bool busy: false
    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Image {
        id: bg
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    // ---- clock -------------------------------------------------------------------------
    Column {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.17)
        spacing: 10
        opacity: 0
        NumberAnimation on opacity { to: 1; duration: 320; easing.type: Easing.OutCubic }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.textPrimary
            font.family: root.monoFont
            font.pixelSize: 132
            font.weight: Font.Medium
            renderType: Text.NativeRendering
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property var days: ["日", "一", "二", "三", "四", "五", "六"]
            text: (root.now.getMonth() + 1) + " 月 " + root.now.getDate() + " 日  星期" + days[root.now.getDay()]
            color: root.textSecondary
            font.family: root.uiFont
            font.pixelSize: 24
            font.letterSpacing: 1
        }
    }

    // ---- card ------------------------------------------------------------------------
    Item {
        id: card
        width: 460
        height: content.implicitHeight + 68
        x: Math.round((root.width - width) / 2)
        y: Math.round(root.height * 0.5)
        opacity: 0

        property real shake: 0
        transform: Translate { x: card.shake }

        NumberAnimation on opacity { to: 1; duration: 320; easing.type: Easing.OutCubic }

        // solid surface, same #17191E as the app-layer content area
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "#17191E"
        }
        // 1px frame + faint top highlight
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"
            border.width: 1
            border.color: root.frame
        }
        Rectangle {
            x: root.radius; y: 1
            width: parent.width - root.radius * 2; height: 1
            color: "#14FFFFFF"
        }

        // hidden models
        ListView {
            id: users
            width: 1; height: 1; visible: false
            model: userModel
            currentIndex: userModel.lastIndex
            delegate: Item {
                width: 1; height: 1
                readonly property string uname: model.name
                readonly property string real: model.realName
            }
        }
        ListView {
            id: sessions
            width: 1; height: 1; visible: false
            model: sessionModel
            currentIndex: sessionModel.lastIndex
            delegate: Item {
                width: 1; height: 1
                readonly property string sname: model.name
            }
        }

        Column {
            id: content
            x: 34; y: 34
            width: parent.width - 68
            spacing: 0

            Text {
                text: users.currentItem && users.currentItem.real ? users.currentItem.real
                    : users.currentItem ? users.currentItem.uname : ""
                color: root.textPrimary
                font.family: root.uiFont
                font.pixelSize: 26
                font.bold: true
            }
            Text {
                topPadding: 4
                text: "輸入密碼以登入"
                color: root.textMuted
                font.family: root.uiFont
                font.pixelSize: 16
            }

            Item { width: 1; height: 26 }

            // placeholder-as-label line field
            Item {
                width: parent.width
                height: 46
                TextInput {
                    id: password
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -2
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.textPrimary
                    selectionColor: root.textMuted
                    font.family: root.uiFont
                    font.pixelSize: 21
                    clip: true
                    enabled: !root.busy
                    focus: true
                    onAccepted: root.doLogin()
                    onTextChanged: root.failed = false
                    Text {
                        visible: password.text.length === 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: "密碼"
                        color: root.textMuted
                        font: password.font
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: root.failed ? root.danger
                         : password.activeFocus ? root.textSecondary : root.frame
                    Behavior on color { ColorAnimation { duration: root.fastDuration } }
                }
            }

            Text {
                topPadding: 8
                height: 30
                text: root.failed ? "密碼錯誤"
                    : keyboard.capsLock ? "大寫鎖定已開啟" : ""
                color: root.danger
                font.family: root.uiFont
                font.pixelSize: 15
            }

            Item { width: 1; height: 8 }

            // the one filled primary action
            Rectangle {
                id: loginButton
                width: parent.width
                height: 50
                radius: root.radius
                color: root.textPrimary
                opacity: password.text.length === 0 || root.busy ? 0.35
                       : loginArea.containsMouse ? 0.88 : 1
                Behavior on opacity { NumberAnimation { duration: root.fastDuration } }
                Text {
                    anchors.centerIn: parent
                    text: root.busy ? "登入中…" : "登入"
                    color: "#111318"
                    font.family: root.uiFont
                    font.pixelSize: 18
                    font.bold: true
                }
                MouseArea {
                    id: loginArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.doLogin()
                }
            }

            Item { width: 1; height: 22 }

            Rectangle { width: parent.width; height: 1; color: root.frame }

            Item { width: 1; height: 14 }

            // plain text buttons
            Item {
                width: parent.width
                height: 20

                Text {
                    id: sessionLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: sessions.currentItem ? sessions.currentItem.sname : ""
                    color: sessionArea.containsMouse ? root.textPrimary : root.textMuted
                    font.family: root.uiFont
                    font.pixelSize: 16
                    Behavior on color { ColorAnimation { duration: root.fastDuration } }
                    MouseArea {
                        id: sessionArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        onClicked: if (sessions.count > 0)
                            sessions.currentIndex = (sessions.currentIndex + 1) % sessions.count
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18
                    Repeater {
                        model: [
                            { label: "睡眠", ok: sddm.canSuspend, act: 0 },
                            { label: "重新啟動", ok: sddm.canReboot, act: 1 },
                            { label: "關機", ok: sddm.canPowerOff, act: 2 }
                        ]
                        delegate: Text {
                            visible: modelData.ok
                            text: modelData.label
                            color: area.containsMouse ? root.textPrimary : root.textMuted
                            font.family: root.uiFont
                            font.pixelSize: 16
                            Behavior on color { ColorAnimation { duration: root.fastDuration } }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                onClicked: modelData.act === 0 ? sddm.suspend()
                                         : modelData.act === 1 ? sddm.reboot() : sddm.powerOff()
                            }
                        }
                    }
                }
            }
        }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: card; property: "shake"; to: -10; duration: 50 }
            NumberAnimation { target: card; property: "shake"; to: 9;   duration: 70 }
            NumberAnimation { target: card; property: "shake"; to: -6;  duration: 60 }
            NumberAnimation { target: card; property: "shake"; to: 0;   duration: 60 }
        }
    }

    function doLogin() {
        if (busy || password.text.length === 0 || !users.currentItem)
            return
        busy = true
        sddm.login(users.currentItem.uname, password.text, sessions.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            root.failed = true
            password.text = ""
            password.forceActiveFocus()
            shakeAnim.restart()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
