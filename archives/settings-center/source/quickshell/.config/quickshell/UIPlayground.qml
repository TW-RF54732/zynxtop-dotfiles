import QtQuick
import QtQuick.Window
import Quickshell
import "components"
import "inputmethod"

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
        property bool hasNext: true
        property int pageNumber: 1
        property int pageDirection: 0
        property var candidates: [
            { label: "1", text: "中文", selectable: true },
            { label: "2", text: "中聞", selectable: true },
            { label: "3", text: "忠文", selectable: true },
            { label: "4", text: "中午", selectable: true },
            { label: "5", text: "中心", selectable: true }
        ]
        function select(index) { selectedIndex = index }
        function previousPage() { if (pageNumber > 1) setPage(pageNumber - 1) }
        function nextPage() { if (pageNumber < 3) setPage(pageNumber + 1) }
        function setPage(page) {
            pageDirection = page > pageNumber ? 1 : -1
            pageNumber = page
            hasPrevious = page > 1
            hasNext = page < 3
            selectedIndex = 0
            const words = page === 1 ? ["中文", "中聞", "忠文", "中午", "中心", "中間", "中國", "中學", "中央", "中山"]
                : page === 2 ? ["終點", "鐘聲", "忠心", "中秋", "中華", "中壢", "中原", "中部", "中正", "中立"]
                : ["種子", "重心", "仲夏", "眾人", "重點"]
            candidates = words.map((text, index) => ({label: String((index + 1) % 10), text: text, selectable: true}))
        }
        function move(delta) {
            // Match the full snapshots used by the real input-method bridge.
            candidates = JSON.parse(JSON.stringify(candidates))
            selectedIndex = Math.max(0, Math.min(candidates.length - 1, selectedIndex + delta))
        }
    }
    Component.onCompleted: demoInputMethod.setPage(1)
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
            Keys.onLeftPressed: demoInputMethod.previousPage()
            Keys.onRightPressed: demoInputMethod.nextPage()
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
                text: "↑ / ↓ 切換選取    ← / → 翻頁    Space 出現／收合"
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
                TextButton { theme: sharedTheme; text: "‹ 上一頁"; onClicked: demoInputMethod.previousPage() }
                TextButton { theme: sharedTheme; text: "下一頁 ›"; onClicked: demoInputMethod.nextPage() }
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
                CandidatePanel {
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
