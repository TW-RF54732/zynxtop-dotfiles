pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "app"
import "services"

// WireGuard window (app layer): glass sidebar with the tunnel list, solid content with the
// selected tunnel or the sentence-style add form.
FloatingWindow {
    id: root

    required property var theme
    required property WireGuardService wireguard
    property bool addMode: false

    readonly property var statusNames: ({
        CONNECTED: "已連線", DISCONNECTED: "未連線", CONNECTING: "連線中…",
        DISCONNECTING: "中斷中…", FAILED: "失敗", CHECKING: "檢查中…", UNAVAILABLE: "無法取得"
    })
    readonly property string statusText: statusNames[wireguard.displayStatus] || wireguard.displayStatus
    readonly property string actionText: {
        if (wireguard.busy) return statusText;
        if (wireguard.activeState === "active") return "中斷連線";
        if (wireguard.activeState === "inactive" || wireguard.activeState === "failed") return "連線";
        return "重試";
    }

    title: "WireGuard"
    visible: false
    implicitWidth: theme.wireguard.width
    implicitHeight: theme.wireguard.height
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: Qt.size(implicitWidth, implicitHeight)
    color: "transparent"

    function present() {
        visible = true;
        minimized = false;
        wireguard.refresh();
    }
    function dismiss() {
        closeEditor();
        visible = false;
    }
    function toggleVisibility() {
        if (visible) dismiss();
        else present();
    }
    function openEditor() {
        wireguard.addError = "";
        nameField.text = "";
        configInput.text = "";
        addMode = true;
        Qt.callLater(() => nameField.focusInput());
    }
    function closeEditor() {
        addMode = false;
        nameField.text = "";
        configInput.text = "";
        wireguard.addError = "";
    }
    function save() {
        if (saveButton.interactive) wireguard.addConfiguration(nameField.text, configInput.text);
    }

    onVisibleChanged: wireguard.monitoring = visible
    onClosed: dismiss()

    Connections {
        target: root.wireguard
        function onConfigurationAdded() { root.closeEditor(); }
    }

    IpcHandler {
        target: "wireguard"
        function show(): void { root.present(); }
        function hide(): void { root.dismiss(); }
        function toggle(): void { root.toggleVisibility(); }
    }

    Item {
        id: content
        anchors.fill: parent

        // Glass: Hyprland blurs whatever shows through this translucent base.
        Rectangle { anchors.fill: parent; color: root.theme.app.glass }

        // ---- title bar ----
        AppTitleBar {
            id: titleBar
            width: parent.width
            theme: root.theme
            title: "WireGuard"
            subtitle: root.wireguard.profiles.length + " 個通道"
            onMoveRequested: root.startSystemMove()

            AppButton {
                theme: root.theme
                text: "關閉"
                onClicked: root.dismiss()
            }
        }

        // ---- glass sidebar: tunnels ----
        Column {
            id: sidebar
            x: 16
            y: titleBar.height + 4
            width: root.theme.wireguard.sidebarWidth - 32
            spacing: 2

            SectionLabel {
                theme: root.theme
                text: "通道"
            }

            Repeater {
                model: root.wireguard.profiles
                ListRow {
                    id: row
                    required property string modelData
                    width: sidebar.width
                    theme: root.theme
                    text: modelData
                    mono: true
                    selected: !root.addMode && modelData === root.wireguard.selectedProfile
                    onClicked: {
                        root.closeEditor();
                        root.wireguard.selectedProfile = modelData;
                    }

                    StatusDot {
                        x: 9
                        anchors.verticalCenter: parent.verticalCenter
                        theme: root.theme
                        on: row.modelData === root.wireguard.selectedProfile && root.wireguard.connected
                    }
                }
            }

            Item { width: 1; height: 6 }

            ListRow {
                width: sidebar.width
                theme: root.theme
                text: "＋ 新增通道"
                textX: 8
                muted: true
                selected: root.addMode
                interactive: !root.wireguard.busy && !root.wireguard.adding
                onClicked: root.openEditor()
            }
        }

        // ---- solid content ----
        ContentSurface {
            id: main
            theme: root.theme
            x: root.theme.wireguard.sidebarWidth
            y: titleBar.height
            width: parent.width - x
            height: parent.height - y

            // Selected tunnel.
            Item {
                anchors.fill: parent
                anchors.margins: root.theme.wireguard.padding
                visible: !root.addMode

                Column {
                    id: detail
                    width: parent.width
                    spacing: 14

                    Row {
                        spacing: 12
                        UiText {
                            id: profileTitle
                            theme: root.theme
                            text: root.wireguard.selectedProfile
                            mono: true
                            font.pixelSize: root.theme.app.titleSize + 3
                            font.bold: true
                            color: root.theme.colors.textPrimary
                        }
                        Row {
                            anchors.verticalCenter: profileTitle.verticalCenter
                            spacing: 6
                            StatusDot {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7; height: 7
                                theme: root.theme
                                on: root.wireguard.connected
                            }
                            UiText {
                                theme: root.theme
                                text: root.statusText
                                font.pixelSize: 12
                                color: root.wireguard.connected
                                    ? root.theme.colors.textPrimary : root.theme.colors.textMuted
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: root.theme.app.line }

                    Grid {
                        columns: 2
                        columnSpacing: 18
                        rowSpacing: 8
                        Repeater {
                            model: [
                                "介面", root.wireguard.selectedProfile,
                                "服務", root.wireguard.unitName(root.wireguard.selectedProfile),
                                "設定檔", "/etc/wireguard/" + root.wireguard.selectedProfile + ".conf"
                            ]
                            UiText {
                                required property string modelData
                                required property int index
                                theme: root.theme
                                text: modelData
                                mono: index % 2 === 1
                                font.pixelSize: 12
                                color: index % 2 === 0 ? root.theme.colors.textMuted : root.theme.colors.textSecondary
                            }
                        }
                    }
                }

                // systemctl status output when the service fails.
                AppCard {
                    anchors.top: detail.bottom
                    anchors.topMargin: 18
                    anchors.bottom: actionRow.top
                    anchors.bottomMargin: 18
                    width: parent.width
                    visible: root.wireguard.error !== ""
                    theme: root.theme
                    radius: root.theme.app.eventRadius

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true
                        UiText {
                            theme: root.theme
                            width: main.width - 2 * root.theme.wireguard.padding - 24
                            text: root.wireguard.error
                            mono: true
                            font.pixelSize: 11
                            lineHeight: 1.25
                            wrapMode: Text.Wrap
                        }
                    }
                }

                Item {
                    id: actionRow
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 30
                    UiText {
                        theme: root.theme
                        anchors.verticalCenter: parent.verticalCenter
                        text: "透過 PolicyKit 驗證，不改變開機啟用狀態"
                        font.pixelSize: 11
                        color: root.theme.colors.textMuted
                    }
                    AppButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        theme: root.theme
                        primary: true
                        text: root.actionText
                        interactive: !root.wireguard.busy && !root.wireguard.adding
                        onClicked: root.wireguard.toggle()
                    }
                }
            }

            // Add form: sentence-style, no field labels; placeholders name the fields.
            Item {
                anchors.fill: parent
                anchors.margins: root.theme.wireguard.padding
                visible: root.addMode

                Column {
                    id: formHead
                    width: parent.width
                    spacing: 16
                    UiText {
                        theme: root.theme
                        text: "新增通道"
                        font.pixelSize: root.theme.app.titleSize
                        font.bold: true
                        color: root.theme.colors.textPrimary
                    }
                    LineField {
                        id: nameField
                        theme: root.theme
                        width: parent.width
                        mono: true
                        placeholder: "名稱：home、office、wg0…"
                        alwaysUnderline: true
                        onAccepted: configInput.focusInput()
                    }
                }

                TextBox {
                    id: configInput
                    anchors.top: formHead.bottom
                    anchors.topMargin: 18
                    anchors.bottom: formFoot.top
                    anchors.bottomMargin: 14
                    width: parent.width
                    theme: root.theme
                    placeholder: "貼上完整的 wg-quick 設定\n\n[Interface]\nPrivateKey = …\nAddress = …\n\n[Peer]\nPublicKey = …"
                }

                Column {
                    id: formFoot
                    anchors.bottom: parent.bottom
                    width: parent.width
                    spacing: 12
                    UiText {
                        theme: root.theme
                        width: parent.width
                        wrapMode: Text.Wrap
                        font.pixelSize: 11
                        lineHeight: 1.25
                        text: root.wireguard.addError
                            || "只貼上可信任的設定：PreUp／PostUp 等 hook 會由 wg-quick 以 root 執行。"
                        color: root.wireguard.addError ? root.theme.colors.textPrimary : root.theme.colors.textMuted
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
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeEditor()
                            }
                        }
                        AppButton {
                            id: saveButton
                            theme: root.theme
                            primary: true
                            text: root.wireguard.adding ? "儲存中…" : "儲存"
                            interactive: !root.wireguard.adding
                                && nameField.text.trim().length > 0
                                && configInput.text.trim().length > 0
                            onClicked: root.save()
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.addMode ? root.closeEditor() : root.dismiss()
    }
    Shortcut {
        sequence: "Ctrl+Return"
        enabled: root.addMode
        onActivated: root.save()
    }
}
