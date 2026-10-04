pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"
import "../services"

FloatingWindow {
    id: root
    required property var theme
    required property var audio
    required property var wireguard
    title: "設定 — Settings"
    visible: true
    implicitWidth: 1040
    implicitHeight: 760
    minimumSize: Qt.size(760, 520)
    color: theme.colors.surface
    property var snapshot: ({fields: [], pages: [], values: {}, capabilities: {}, unavailable: []})
    property var changes: ({})
    property string page: "appearance"
    property string pendingPage: ""
    property bool pendingClose: false
    property bool busy: false
    property bool ready: false
    property string status: "正在讀取設定…"
    property string information: ""
    property bool conflict: false
    property var monitors: []
    property string queryTopic: ""
    property real previewDeadline: 0
    property int remaining: 0
    readonly property bool localDirty: Object.keys(changes).length > 0
    readonly property bool dirty: localDirty || (page === "monitors" && monitorEditor.dirty) || services.dirty
    function send(request) { if (request.op === "inspect") queryTopic = request.topic; busy = true; backend.send(request) }
    function edit(key, value) {
        let next = Object.assign({}, changes)
        if (value === snapshot.values[key]) delete next[key]
        else next[key] = value
        changes = next
    }
    function value(key) { return changes[key] === undefined ? snapshot.values[key] : changes[key] }
    function finishPending() {
        if (pendingPage) { page = pendingPage; pendingPage = "" }
        if (pendingClose) { pendingClose = false; storeWindowState(); visible = false }
    }
    function resetDrafts() { changes = ({}); monitorEditor.reset(); services.reset() }
    function apply() {
        if (page === "monitors" && monitorEditor.dirty) monitorEditor.preview()
        else if (services.dirty) services.apply()
        else send({op: "apply", revision: snapshot.revision, changes: changes})
    }
    function navigate(id) {
        if (id === page) return
        if (remaining > 0) { status = "請先確認或還原螢幕預覽"; return }
        if (dirty) { pendingPage = id; unsaved.open(); return }
        page = id; information = ""
    }
    function present() {
        visible = true; minimized = false
        activation.restart()
    }
    function closeRequested() {
        if (remaining > 0) send({op: "monitor-cancel"})
        if (dirty) { pendingClose = true; visible = true; unsaved.open() }
        else { storeWindowState(); visible = false }
    }
    Timer {
        id: activation
        interval: 80
        onTriggered: {
            const window = ToplevelManager.toplevels.values.find(t => t.appId === Quickshell.appId)
            if (window) window.activate()
            if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) {
                const selector = "class:^" + Quickshell.appId.replace(/\./g, "[.]") + "$"
                Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({window=" + JSON.stringify(selector) + "})"])
            }
        }
    }
    FileView {
        id: windowState
        path: Quickshell.stateDir + "/window.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                let state = JSON.parse(text())
                if (Number.isFinite(state.width)) root.implicitWidth = Math.max(760, Math.min(2400, state.width))
                if (Number.isFinite(state.height)) root.implicitHeight = Math.max(520, Math.min(1600, state.height))
            } catch (e) { /* Invalid window state uses the default size. */ }
        }
    }
    function storeWindowState() { windowState.setText(JSON.stringify({width:width,height:height})) }
    onClosed: closeRequested()
    IpcHandler {
        target: "settings"
        function show(): void { root.present() }
        function openPage(pageId: string): void {
            root.present()
            if (!root.ready) root.pendingPage = pageId
            else if (root.snapshot.pages.some(p => p.id === pageId)) root.navigate(pageId)
        }
    }
    JsonProcessService {
        id: backend
        command: ["python3", "-B", "-u", Qt.resolvedUrl("backend.py").toString().replace("file://", "")]
        onRunningChanged: if (running) { root.busy = true; send({op: "read"}) }
        onDisconnected: { root.busy = false; root.status = "後端連線中斷；修改尚未保存" }
        onMessageReceived: message => {
            root.busy = false
            if (message.kind === "revision") {
                if (root.ready && message.revision !== root.snapshot.revision) { root.conflict = true; root.status = "設定已被外部修改。請還原修改並重新載入。" }
                return
            }
            if (!message.ok) { root.status = message.error; return }
            if (message.kind === "snapshot") {
                root.snapshot = message; root.changes = ({}); root.ready = true; root.conflict = false; root.remaining = 0
                monitorEditor.original = JSON.parse(JSON.stringify(monitorEditor.draft))
                root.wireguard.profilesPath = message.wireguardPath
                if (root.pendingPage) root.page = root.pendingPage
                root.status = "設定已載入；只保存修改的項目"
                if (root.pendingClose) { root.pendingClose = false; root.visible = false }
                if (root.pendingPage) { root.page = root.pendingPage; root.pendingPage = "" }
            } else if (message.kind === "network-profile") services.loadNetwork(message)
            else if (message.kind === "monitor-cancelled") { root.remaining = 0; monitorEditor.reset(); root.status = message.text }
            else if (message.kind === "info") { if (root.queryTopic === "monitors") root.monitors = JSON.parse(message.text); else root.information = message.text }
            else if (message.kind === "preview") { root.previewDeadline = message.deadline; root.remaining = Math.max(0, Math.ceil(message.deadline - Date.now()/1000)); root.status = message.text }
            else { root.status = message.text; if (message.resetDraft) { services.networkOriginal = null; services.reset(); root.finishPending() } }
        }
    }
    Timer {
        interval: 2500; repeat: true; running: root.ready && root.visible
        onTriggered: if (!root.busy && backend.running) backend.send({op:"revision"})
    }
    Timer { interval: 1000; repeat: true; running: root.remaining > 0; onTriggered: { root.remaining = Math.max(0, Math.ceil(root.previewDeadline - Date.now()/1000)); if (!root.remaining) { monitorEditor.reset(); root.pendingPage = ""; root.pendingClose = false; root.status = "預覽已逾時，螢幕已自動還原" } } }
    Dialog {
        id: unsaved
        anchors.centerIn: parent
        title: "尚未保存修改"
        modal: true
        ColumnLayout {
            Label { text: "離開前要如何處理目前頁面的修改？" }
            RowLayout {
                Button { text: "套用"; enabled: !root.busy; onClicked: { unsaved.close(); root.apply() } }
                Button { text: "捨棄修改"; onClicked: {
                    root.resetDrafts()
                    if (root.pendingPage) root.page = root.pendingPage
                    if (root.pendingClose) { root.storeWindowState(); root.visible = false }
                    root.pendingPage = ""; root.pendingClose = false; unsaved.close()
                } }
                Button { text: "繼續編輯"; onClicked: { root.pendingPage = ""; root.pendingClose = false; unsaved.close() } }
            }
        }
    }
    Pane {
        anchors.fill: parent
        padding: 0
        font.family: root.theme.typography.family
        font.pixelSize: root.theme.typography.bodySize
        palette {
            window: root.theme.colors.surface
            windowText: root.theme.colors.textPrimary
            base: root.theme.colors.frame
            text: root.theme.colors.textPrimary
            button: root.theme.colors.frame
            buttonText: root.theme.colors.textPrimary
            highlight: root.theme.colors.textMuted
            highlightedText: root.theme.colors.textPrimary
            placeholderText: root.theme.colors.textMuted
        }
        background: Rectangle { color: "transparent"; border.color: root.theme.colors.frame; border.width: 2; radius: root.theme.geometry.cornerRadius }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            MonoText { theme: root.theme; text: "設定"; font.pixelSize: 24 }
            Item { Layout.fillWidth: true; implicitHeight: 32; MouseArea { anchors.fill: parent; onPressed: root.startSystemMove() } }
            TextField { id: search; placeholderText: "搜尋設定…"; Layout.preferredWidth: 260 }
            Button { text: "關閉"; onClicked: root.closeRequested() }
        }
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 18
            ScrollView {
                Layout.preferredWidth: 180; Layout.fillHeight: true; clip: true
                ColumnLayout {
                    width: 174
                    Repeater {
                        model: root.snapshot.pages.filter(p => !search.text || p.label.includes(search.text) || root.snapshot.fields.some(f => f.page === p.id && (f.label+f.key).toLowerCase().includes(search.text.toLowerCase())))
                        delegate: TextButton {
                            required property var modelData
                            theme: root.theme
                            Layout.fillWidth: true
                            text: modelData.label
                            active: root.page === modelData.id
                            onClicked: root.navigate(modelData.id)
                        }
                    }
                }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: scroll.availableWidth
                    spacing: 16
                    MonoText { theme: root.theme; text: root.snapshot.pages.find(p => p.id === root.page)?.label || ""; font.pixelSize: 22 }
                    MonoText { theme: root.theme; Layout.fillWidth: true; wrapMode: Text.Wrap; text: root.page === "kitty" ? "Kitty 設定於新視窗生效。" : "即時操作會立即生效；其他修改請按下套用。" }
                    Repeater {
                        model: root.snapshot.fields.filter(f => (f.page === root.page && (!search.text || (f.label + f.key).toLowerCase().includes(search.text.toLowerCase()))))
                        delegate: RowLayout {
                            id: fieldRow
                            required property var modelData
                            Layout.fillWidth: true
                            enabled: root.ready && !root.busy && (!(["hypr","bind","program"].includes(modelData.target)) || (root.snapshot.capabilities.hyprland && !root.snapshot.unavailable.includes(modelData.key))) && (modelData.target !== "idle" || (!!root.snapshot.capabilities.hypridle && !!root.snapshot.capabilities.hyprlock))
                            MonoText { theme: root.theme; text: fieldRow.modelData.label; Layout.fillWidth: true; wrapMode: Text.Wrap }
                            Switch { visible: fieldRow.modelData.type === "bool"; checked: root.value(fieldRow.modelData.key) === true; onToggled: root.edit(fieldRow.modelData.key, checked) }
                            TextField {
                                visible: fieldRow.modelData.type !== "bool"
                                Layout.preferredWidth: 240
                                text: String(root.value(fieldRow.modelData.key) ?? "")
                                onTextEdited: root.edit(fieldRow.modelData.key, fieldRow.modelData.type === "number" ? Number(text) : text)
                            }
                        }
                    }
                    ServicePage {
                        id: services
                        Layout.fillWidth: true
                        page: root.page; theme: root.theme; audio: root.audio; wireguard: root.wireguard
                        capabilities: root.snapshot.capabilities; busy: root.busy
                        onRequest: request => root.send(request)
                    }
                    MonitorEditor {
                        id: monitorEditor
                        visible: root.page === "monitors"
                        Layout.fillWidth: true
                        theme: root.theme; devices: root.monitors; available: !!root.snapshot.capabilities.hyprland
                        busy: root.busy; remaining: root.remaining
                        onRequest: message => root.send(message)
                    }
                    TextArea { Layout.fillWidth: true; visible: root.information !== ""; text: root.information; readOnly: true; wrapMode: TextEdit.Wrap; color: root.theme.colors.textSecondary; background: Rectangle { color: root.theme.colors.frame } }
                    Item { Layout.preferredHeight: 12 }
                }
            }
        }
        MonoText { theme: root.theme; text: root.status; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12 }
        RowLayout {
            Layout.fillWidth: true
            Button { text: "重新載入"; enabled: !root.busy && !root.dirty; onClicked: root.send({op:"read"}) }
            Button { text: "移除此頁覆寫"; enabled: root.ready && !root.busy; onClicked: {
                let next = Object.assign({}, root.changes)
                root.snapshot.fields.filter(f => f.page === root.page).forEach(f => { if (root.snapshot.overrides[f.key] !== undefined) next[f.key] = null })
                root.changes = next
            } }
            Item { Layout.fillWidth: true }
            Button { text: "還原修改"; enabled: root.dirty && !root.busy; onClicked: root.resetDrafts() }
            Button { text: root.busy ? "處理中…" : "套用"; enabled: root.dirty && !root.busy && !root.conflict && root.remaining === 0; onClicked: root.apply() }
        }
    }
    }
    MouseArea { anchors.right: parent.right; anchors.bottom: parent.bottom; width: 14; height: 14; cursorShape: Qt.SizeFDiagCursor; onPressed: root.startSystemResize(Qt.RightEdge | Qt.BottomEdge) }
}
