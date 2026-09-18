import QtQuick
import QtQuick.Window
import Quickshell
import "components"
import "examples"

ShellRoot {
    id: root
    Style { id: sharedTheme }
    QtObject {
        id: demoInputMethod
        property string preedit: "ㄓㄨㄥ ㄨㄣˊ"
        property string auxiliary: ""
        property int selectedIndex: 0
        property int layoutHint: 0
        property bool hasPrevious: false
        property bool hasNext: false
        property var candidates: [
            { label: "1", text: "中文", selectable: true },
            { label: "2", text: "中聞", selectable: true },
            { label: "3", text: "忠文", selectable: true },
            { label: "4", text: "中午", selectable: true },
            { label: "5", text: "中心", selectable: true }
        ]
        function select(index) { selectedIndex = index }
        function previousPage() {}
        function nextPage() {}
        function move(delta) {
            // Match the full snapshots used by the real input-method bridge.
            candidates = JSON.parse(JSON.stringify(candidates))
            selectedIndex = Math.max(0, Math.min(candidates.length - 1, selectedIndex + delta))
        }
    }
    Window {
        id: window
        width: 880
        height: 620
        visible: true
        title: "Quickshell UI Playground"
        color: "#111318"

        Item {
            id: canvas
            anchors.fill: parent
            focus: true
            property string action: ""
            Keys.onUpPressed: { demoInputMethod.move(-1); menu.moveSelection(-1) }
            Keys.onDownPressed: { demoInputMethod.move(1); menu.moveSelection(1) }
            Keys.onSpacePressed: { menu.shown = !menu.shown; candidateMotion.shown = !candidateMotion.shown }

            MonoText {
                theme: sharedTheme
                x: 36; y: 30
                text: "選單、選字與面板動畫"
                font.pixelSize: 22
            }
            MonoText {
                theme: sharedTheme
                x: 36; y: 68
                text: "↑ / ↓ 切換選取    Space 出現／收合"
                tone: sharedTheme.colors.textSecondary
            }
            Row {
                x: 36; y: 108
                spacing: 12
                TextButton {
                    theme: sharedTheme
                    text: "↑"
                    onClicked: { demoInputMethod.move(-1); menu.moveSelection(-1) }
                }
                TextButton {
                    theme: sharedTheme
                    text: "↓"
                    onClicked: { demoInputMethod.move(1); menu.moveSelection(1) }
                }
                TextButton {
                    theme: sharedTheme
                    text: "出現／收合"
                    onClicked: { menu.shown = !menu.shown; candidateMotion.shown = !candidateMotion.shown }
                }
                TextButton {
                    theme: sharedTheme
                    text: "橫排／直排"
                    onClicked: demoInputMethod.layoutHint = demoInputMethod.layoutHint === 1 ? 0 : 1
                }
            }
            MonoText { theme: sharedTheme; x: 36; y: 172; text: "選單 · 向下出現" }
            MonoText { theme: sharedTheme; x: 390; y: 172; text: "選字 · 向上出現" }
            MenuPanel {
                id: menu
                focus: false
                x: 36; y: 210
                theme: sharedTheme
                width: 290
                shown: true
                direction: "down"
                items: [
                    { text: "Dashboard", icon: "dashboard" },
                    { text: "音訊設定", icon: "muted" },
                    { text: "暫時不可用", enabled: false },
                    { text: "網路設定", icon: "offline" },
                    { text: "外觀設定" },
                    { text: "工作區" },
                    { text: "日期與時間", icon: "sun" },
                    { text: "更多項目" },
                    { text: "關閉選單" }
                ]
                onTriggered: (index, entry) => canvas.action = "已選擇：" + entry.text
                onDismissRequested: shown = false
            }
            PanelTransition {
                id: candidateMotion
                x: 390; y: 210
                theme: sharedTheme
                shown: true
                direction: "up"
                implicitWidth: candidatePanel.implicitWidth
                implicitHeight: candidatePanel.implicitHeight
                SmoothCandidatePanel {
                    id: candidatePanel
                    theme: sharedTheme
                    inputMethod: demoInputMethod
                    maximumWidth: 420
                }
            }
            MonoText {
                theme: sharedTheme
                x: 390; y: 530
                text: canvas.action
                tone: sharedTheme.colors.textSecondary
            }
        }
    }
}
