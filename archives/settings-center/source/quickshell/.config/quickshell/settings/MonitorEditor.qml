pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: root
    required property var theme
    required property var devices
    required property bool available
    required property bool busy
    required property int remaining
    property var draft: []
    property var original: []
    readonly property bool dirty: JSON.stringify(draft) !== JSON.stringify(original)
    signal request(var message)
    function reset() { draft = JSON.parse(JSON.stringify(original)) }
    function preview() { request({op:"monitor-preview",monitors:draft}) }
    onDevicesChanged: { original = devices.map(m => ({output:m.name,mode:m.disabled ? "preferred" : m.width+"x"+m.height+"@"+m.refreshRate,position:m.x+"x"+m.y,scale:m.scale,transform:m.transform||0,disabled:m.disabled||false})); reset() }
    function edit(index,key,value) { let copy = draft.slice(); copy[index] = Object.assign({},copy[index]); copy[index][key] = value; draft = copy }
    Button { text: "讀取螢幕"; enabled: root.available && !root.busy && !root.remaining; onClicked: root.request({op:"inspect",topic:"monitors"}) }
    Repeater {
        model: root.devices
        delegate: ColumnLayout {
            id: screenRow
            required property var modelData
            required property int index
            Layout.fillWidth: true
            enabled: !root.busy && root.remaining === 0
            MonoText { theme: root.theme; text: screenRow.modelData.name + " — " + screenRow.modelData.description; Layout.fillWidth: true; wrapMode: Text.Wrap }
            Switch { text: "啟用"; checked: !root.draft[screenRow.index]?.disabled; onToggled: root.edit(screenRow.index,"disabled",!checked) }
            ComboBox { Layout.fillWidth: true; editable: true; model: ["preferred"].concat((screenRow.modelData.availableModes || []).map(m => m.replace("Hz",""))); editText: root.draft[screenRow.index]?.mode || "preferred"; onActivated: root.edit(screenRow.index,"mode",currentText); onAccepted: root.edit(screenRow.index,"mode",editText) }
            RowLayout {
                Label { text: "縮放"; color: root.theme.colors.textSecondary }
                TextField { text: String(root.draft[screenRow.index]?.scale || 1); Layout.preferredWidth: 90; onTextEdited: root.edit(screenRow.index,"scale",Number(text)) }
                Label { text: "位置 XxY"; color: root.theme.colors.textSecondary }
                TextField { text: root.draft[screenRow.index]?.position || "auto"; Layout.fillWidth: true; onTextEdited: root.edit(screenRow.index,"position",text) }
            }
            ComboBox { model: ["正常","旋轉 90°","旋轉 180°","旋轉 270°","翻轉","翻轉 90°","翻轉 180°","翻轉 270°"]; currentIndex: root.draft[screenRow.index]?.transform || 0; onActivated: root.edit(screenRow.index,"transform",currentIndex) }
        }
    }
    RowLayout {
        Button { text: "預覽變更"; enabled: root.draft.length > 0 && !root.busy && !root.remaining; onClicked: root.preview() }
        Button { text: "還原修改"; enabled: !root.busy && !root.remaining; onClicked: root.reset() }
    }
    RowLayout {
        visible: root.remaining > 0
        Button { text: "保留設定（" + root.remaining + " 秒）"; enabled: !root.busy; onClicked: root.request({op:"monitor-confirm"}) }
        Button { text: "立即還原"; enabled: !root.busy; onClicked: root.request({op:"monitor-cancel"}) }
    }
}
