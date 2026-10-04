pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../components"

ColumnLayout {
    id: root
    required property string page
    required property var theme
    required property var audio
    required property var wireguard
    required property var capabilities
    required property bool busy
    property bool dirty: false
    property var networkOriginal: null
    function loadNetwork(message) { networkOriginal = message; reset() }
    function reset() {
        if (networkOriginal) {
            let p = networkOriginal.properties
            autoconnect.checked = p["connection.autoconnect"] === "yes"
            ipv4Method.currentIndex = ["auto","manual","disabled"].indexOf(p["ipv4.method"])
            ipv4Address.text = p["ipv4.addresses"] || ""
            ipv4Gateway.text = p["ipv4.gateway"] || ""
            ipv4Dns.text = p["ipv4.dns"] || ""
        }
        dirty = false
    }
    function apply() { saveNetwork() }
    function saveNetwork() {
        request({op:"network-save",uuid:networkOriginal.uuid,revision:networkOriginal.revision,properties:{"connection.autoconnect":autoconnect.checked?"yes":"no","ipv4.method":ipv4Method.currentText,"ipv4.addresses":ipv4Address.text,"ipv4.gateway":ipv4Gateway.text,"ipv4.dns":ipv4Dns.text}})
    }
    signal request(var request)
    function action(name, arg) { request({op:"action",name:name,arg:arg||""}) }
    function inspect(topic) { request({op:"inspect",topic:topic}) }
    function launch(command) { Quickshell.execDetached(command) }
    property var tools: ({ime:"fcitx5",audio:"wpctl",network:"nmcli",bluetooth:"bluetoothctl",monitors:"hyprland",power:"loginctl",datetime:"timedatectl"})
    MonoText {
        theme: root.theme; Layout.fillWidth: true; wrapMode: Text.Wrap
        visible: !!root.tools[root.page] && !root.capabilities[root.tools[root.page]]
        text: "目前無法使用：缺少元件、服務或裝置（" + (root.tools[root.page] || "") + "）。不會自動安裝。"
    }
    ColumnLayout {
        visible: root.page === "audio"; Layout.fillWidth: true
        Repeater {
            model: [{label:"輸出裝置",input:false},{label:"輸入裝置",input:true}]
            delegate: ColumnLayout {
                id: audioRow
                required property var modelData
                readonly property var node: modelData.input ? root.audio.source : root.audio.sink
                readonly property var nodes: modelData.input ? root.audio.inputs : root.audio.outputs
                Layout.fillWidth: true
                MonoText { theme: root.theme; text: audioRow.modelData.label }
                ComboBox { Layout.fillWidth: true; model: audioRow.nodes.map(n => n.description || n.name); currentIndex: audioRow.nodes.indexOf(audioRow.node); onActivated: index => audioRow.modelData.input ? root.audio.selectInput(audioRow.nodes[index]) : root.audio.selectOutput(audioRow.nodes[index]) }
                Slider { Layout.fillWidth: true; from: 0; to: 1; enabled: !!audioRow.node?.audio; value: audioRow.node?.audio?.volume || 0; onMoved: audioRow.node.audio.volume = value }
                Switch { text: "靜音"; enabled: !!audioRow.node?.audio; checked: audioRow.node?.audio?.muted || false; onToggled: audioRow.node.audio.muted = checked }
            }
        }
        Button { text: "進階混音"; enabled: !!root.capabilities.pavucontrol; onClicked: root.launch(["pavucontrol"]) }
    }
    ColumnLayout {
        visible: root.page === "network"; enabled: !root.busy && !!root.capabilities.nmcli; Layout.fillWidth: true
        RowLayout {
            Button { text: "Wi-Fi 開"; onClicked: root.action("wifi-on") }
            Button { text: "Wi-Fi 關"; onClicked: root.action("wifi-off") }
            Button { text: "掃描 Wi-Fi"; onClicked: root.inspect("wifi") }
        }
        TextField { id: ssid; Layout.fillWidth: true; placeholderText: "Wi-Fi 名稱（SSID）" }
        TextField { id: password; Layout.fillWidth: true; placeholderText: "密碼（僅傳給 NetworkManager）"; echoMode: TextInput.Password }
        Button { text: "連線 Wi-Fi"; enabled: !!ssid.text; onClicked: { root.request({op:"action",name:"wifi-connect",arg:ssid.text,password:password.text}); password.clear() } }
        RowLayout {
            Button { text: "介面狀態"; onClicked: root.inspect("network") }
            Button { text: "已保存連線"; onClicked: root.inspect("connections") }
        }
        TextField { id: connection; enabled: !root.dirty; Layout.fillWidth: true; placeholderText: "連線 UUID（從已保存連線取得）" }
        RowLayout {
            Button { text: "啟用連線"; enabled: !!connection.text; onClicked: root.action("connect",connection.text) }
            Button { text: "忘記連線"; enabled: !!connection.text; onClicked: forget.open() }
        }
        Button { text: "讀取此連線的 IP 與 DNS"; enabled: !!connection.text && !root.dirty; onClicked: root.request({op:"network-read",uuid:connection.text}) }
        TextField { id: iface; Layout.fillWidth: true; placeholderText: "介面名稱（例如 wlan0、enp3s0）" }
        Button { text: "中斷介面連線"; enabled: !!iface.text; onClicked: root.action("disconnect",iface.text) }
        ColumnLayout {
            Layout.fillWidth: true
            enabled: root.networkOriginal !== null && !root.busy
        CheckBox { id: autoconnect; text: "自動連線"; checked: true; onToggled: root.dirty = true }
        ComboBox { id: ipv4Method; model: ["auto","manual","disabled"]; onActivated: root.dirty = true }
        TextField { id: ipv4Address; Layout.fillWidth: true; onTextEdited: root.dirty = true; placeholderText: "靜態 IPv4 / 前綴，例如 192.168.1.10/24" }
        TextField { id: ipv4Gateway; Layout.fillWidth: true; onTextEdited: root.dirty = true; placeholderText: "閘道，例如 192.168.1.1" }
        TextField { id: ipv4Dns; Layout.fillWidth: true; onTextEdited: root.dirty = true; placeholderText: "DNS（逗號分隔；空白使用自動設定）" }
        Button { text: "套用此連線的 IP 與 DNS"; enabled: !!connection.text && root.dirty; onClicked: root.saveNetwork() }
        }
        Button { text: "IP、DNS、自動連線與企業驗證（nmtui）"; enabled: !!root.capabilities.nmtui; onClicked: root.launch(["kitty","-e","nmtui"]) }
        Dialog { id: forget; title: "忘記此連線？"; modal: true; standardButtons: Dialog.Ok | Dialog.Cancel; onAccepted: root.action("forget",connection.text) }
    }
    ColumnLayout {
        visible: root.page === "bluetooth"; enabled: !root.busy && !!root.capabilities.bluetoothctl; Layout.fillWidth: true
        RowLayout {
            Button { text: "開啟藍牙"; onClicked: root.action("bluetooth-on") }
            Button { text: "關閉藍牙"; onClicked: root.action("bluetooth-off") }
            Button { text: "裝置"; onClicked: root.inspect("bluetooth") }
        }
        TextField { id: address; Layout.fillWidth: true; placeholderText: "裝置位址 AA:BB:CC:DD:EE:FF" }
        RowLayout {
            Button { text: "配對"; enabled: !!address.text; onClicked: root.action("pair",address.text) }
            Button { text: "連線"; enabled: !!address.text; onClicked: root.action("bt-connect",address.text) }
            Button { text: "斷線"; enabled: !!address.text; onClicked: root.action("bt-disconnect",address.text) }
        }
    }
    ColumnLayout {
        visible: root.page === "vpn"; Layout.fillWidth: true
        ComboBox { model: root.wireguard.profiles; currentIndex: root.wireguard.profiles.indexOf(root.wireguard.selectedProfile); onActivated: index => { root.wireguard.selectedProfile = root.wireguard.profiles[index]; root.wireguard.refresh() } }
        MonoText { theme: root.theme; text: root.wireguard.displayStatus + "\n" + root.wireguard.error; Layout.fillWidth: true; wrapMode: Text.Wrap }
        RowLayout {
            Button { text: "更新狀態"; onClicked: root.wireguard.refresh() }
            Button { text: root.wireguard.connected ? "斷開 WireGuard" : "連接 WireGuard"; enabled: root.wireguard.canToggle; onClicked: root.wireguard.toggle() }
            Button { text: "Surfshark"; enabled: !!root.capabilities.surfshark; onClicked: root.launch(["surfshark"]) }
        }
    }
    RowLayout {
        visible: root.page === "ime"
        Button { text: "輸入法狀態"; enabled: !!root.capabilities.fcitx5; onClicked: root.inspect("ime") }
        Button { text: "Fcitx5 設定"; enabled: !!root.capabilities["fcitx5-configtool"]; onClicked: root.launch(["fcitx5-configtool"]) }
    }
    ColumnLayout {
        visible: root.page === "datetime"; Layout.fillWidth: true; enabled: !root.busy
        Button { text: "系統時間與時區"; onClicked: root.inspect("datetime") }
        TextField { id: timezone; Layout.fillWidth: true; placeholderText: "時區，例如 Asia/Taipei" }
        Button { text: "設定時區"; enabled: !!timezone.text; onClicked: root.action("timezone",timezone.text) }
        RowLayout {
            Button { text: "啟用自動校時"; onClicked: root.action("ntp-on") }
            Button { text: "停用自動校時"; onClicked: root.action("ntp-off") }
        }
        TextField { id: manualTime; Layout.fillWidth: true; placeholderText: "手動時間：YYYY-MM-DD HH:MM:SS（先停用自動校時）" }
        Button { text: "設定時間"; enabled: !!manualTime.text; onClicked: root.action("time",manualTime.text) }
        TextField { id: realName; Layout.fillWidth: true; placeholderText: "使用者顯示名稱" }
        Button { text: "更新顯示名稱"; enabled: !!root.capabilities.accounts && !!realName.text; onClicked: root.request({op:"account",name:"SetRealName",value:realName.text}) }
        TextField { id: avatar; Layout.fillWidth: true; placeholderText: "頭像圖片完整路徑" }
        Button { text: "更新頭像"; enabled: !!root.capabilities.accounts && !!avatar.text; onClicked: root.request({op:"account",name:"SetIconFile",value:avatar.text}) }
        Button { text: "使用者資料"; onClicked: root.inspect("user") }
    }
    ColumnLayout {
        visible: root.page === "power"; Layout.fillWidth: true; enabled: !root.busy
        RowLayout {
            Button { text: "能力與狀態"; onClicked: root.inspect("power") }
            Button { text: "鎖定"; enabled: !!root.capabilities.hyprlock; onClicked: root.launch(["hyprlock"]) }
            Button { text: "睡眠"; onClicked: suspend.open() }
        }
        Dialog { id: suspend; title: "現在進入睡眠？"; modal: true; standardButtons: Dialog.Ok | Dialog.Cancel; onAccepted: root.action("suspend") }
        ComboBox { id: powerProfile; model: ["balanced","power-saver","performance"]; enabled: !!root.capabilities.powerprofilesctl; onActivated: root.action("profile",currentText) }
        Slider { from: 1; to: 100; value: 50; enabled: !!root.capabilities.brightnessctl; onPressedChanged: if (!pressed) root.action("brightness",Math.round(value)+"%") }
        MonoText { theme: root.theme; text: "省電模式與背光需服務及硬體支援；操作失敗會顯示原因。"; Layout.fillWidth: true; wrapMode: Text.Wrap }
    }
    ColumnLayout {
        visible: root.page === "applications"; Layout.fillWidth: true
        TextField { id: desktopId; Layout.fillWidth: true; placeholderText: "應用程式 desktop ID，例如 firefox.desktop" }
        ComboBox { id: mime; Layout.fillWidth: true; editable: true; model: ["x-scheme-handler/http","x-scheme-handler/https","text/html","inode/directory","application/pdf","text/plain","image/png"] }
        Button { text: "設為 MIME 預設程式"; enabled: !root.busy && !!desktopId.text; onClicked: root.request({op:"default-app",desktop:desktopId.text,mime:mime.editText}) }
        Button { text: "登入啟動應用"; onClicked: root.inspect("autostart") }
        TextField { id: autoName; Layout.fillWidth: true; placeholderText: "啟動項目名稱（英數字）" }
        TextField { id: autoExec; Layout.fillWidth: true; placeholderText: "執行命令（Desktop Entry Exec 格式）" }
        RowLayout {
            Button { text: "新增／啟用"; enabled: !!autoName.text && !!autoExec.text && !root.busy; onClicked: root.request({op:"autostart",name:autoName.text,command:autoExec.text,enabled:true}) }
            Button { text: "停用"; enabled: !!autoName.text && !root.busy; onClicked: root.request({op:"autostart",name:autoName.text,command:autoExec.text,enabled:false}) }
            Button { text: "移除"; enabled: !!autoName.text && !root.busy; onClicked: root.request({op:"autostart-remove",name:autoName.text}) }
        }
    }
    ColumnLayout {
        visible: root.page === "about"; Layout.fillWidth: true
        Button { text: "系統資訊"; onClicked: root.inspect("about") }
        MonoText { theme: root.theme; text: Object.keys(root.capabilities).map(k => k + "：" + (root.capabilities[k] ? "可用" : "不可用")).join("\n"); Layout.fillWidth: true; wrapMode: Text.Wrap }
    }
}
