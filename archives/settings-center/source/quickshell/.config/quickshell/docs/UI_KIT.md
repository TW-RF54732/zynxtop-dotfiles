# 快速組裝 Shell UI

共用元件提供選單、選取移動、捲動回彈和上下出現／收合。服務只提供資料與操作；元件管理畫面與動畫，不需要每個功能重新實作。

## 直接組裝選單

```qml
import "components"

MenuPanel {
    theme: sharedTheme
    shown: menuOpen
    direction: "down"
    items: [
        { text: "Dashboard", icon: "dashboard" },
        { text: "音訊設定", icon: "muted" },
        { text: "不可用", enabled: false }
    ]
    onTriggered: (index, entry) => handleAction(index)
    onDismissRequested: menuOpen = false
}
```

MenuPanel 共用玻璃框、凹弧反白、鍵盤選取、hover、滑鼠點擊、清單捲動與開關動畫；停用的項目不會被啟動，鍵盤也會略過。`items` 使用純顯示資料：`text`、可選 `icon`、可選 `enabled`。Icon 名稱使用 MonoIcon 支援的單色圖示。

## 包裝任意面板的出現動畫

```qml
PanelTransition {
    theme: sharedTheme
    shown: panelOpen
    direction: "up"
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    MyPanel { id: panel; theme: sharedTheme }
}
```

`direction` 指出現時的移動方向，可用 up、down、left、right、none；none 只淡入淡出。可覆寫 `distance`、`duration`。動畫只修改透明度及平移，不反覆改變內容尺寸。關閉期間保留顯示、停止接收操作，完成後才隱藏；快速反向開關從目前進度接續。

包裝 layer-shell 視窗時，視窗的 visible 必須跟隨 transition.visible，不能直接跟隨 panelOpen，否則收合動畫會被提前切斷。視窗需為位移預留透明空間；layer-shell、螢幕定位與外部點擊關閉仍由外層視窗負責。

## 元件分工

| 元件 | 負責 |
| --- | --- |
| StableListModel | 純顯示資料的局部更新；相同候選字 snapshot 不重設模型 |
| SelectionHighlight | 一塊反白在項目之間移動；支援圓角與外框凹弧 |
| AnimatedListView | 共用捲動動畫、可見範圍定位與邊界回彈 |
| SelectableList | 固定列高清單、可見列數、選取請求、捲動與回彈 |
| SelectableFlow | 直排或橫排換行、穩定資料更新、寬度測量與選取移動 |
| MenuRow | 選單文字、可選圖示及停用狀態 |
| MenuPanel | 組合以上元件與玻璃框、出現動畫 |
| PanelTransition | 任意面板的平移、淡入淡出與可中斷開關 |

SelectableList 接收 `model`、`delegate`、`currentIndex`、`rowHeight` 等屬性，發出 selectionRequested(index) 與 activationRequested()；呼叫端更新 currentIndex。`moveSelection(delta)` 處理上下切換。外框凹弧用 insetSelection，若內容已扣除外框，設定 selectionInset 為外框寬度。

選取位置與捲動位移分開動畫，避免同一個捲動位移被插值兩次。回彈使用視覺平移，ListView.contentY 保持在有效範圍。鍵盤切換時，只有真正移動滑鼠才重新啟用 hover 選取，避免捲動把鍵盤選取改成滑鼠下方的列。

examples/SmoothCandidateList 示範如何以 SelectableFlow 保留候選字資料，寬度只在內容改變時一次更新；使用單一 SelectionHighlight 移動反白，不再讓每列背景分別交叉淡入。Flow 的橫排與換行仍保留，反白跟隨實際列位置。

## 預覽與檢查

```sh
qs -p UIPlayground.qml
bash tests/run-ui-kit.sh
bash tests/run-smoke.sh
```

預覽使用本地示範資料，不註冊 Fcitx panel、不連接正式輸入法服務。上下鍵切換，Space 開關動畫，也可用按鈕操作。測試使用設定副本、offscreen、獨立 runtime/state，不操作正式桌面或 qmlls 連結。

正式的 inputmethod/CandidateList 已使用 StableListModel、SelectableList 與 SelectableFlow，保留七列上限、直向捲動與橫向翻頁；launcher/ResultsList 共用同一套清單動畫。InputMethodWindow 的定位、關閉快照及 RevealSurface 仍由既有視窗元件管理。
