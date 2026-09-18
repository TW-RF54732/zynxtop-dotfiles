# QML 中文候選框

`shell.qml` 建立一個 `InputMethodService`，再將服務、主題和 compositor 注入 `InputMethodWindow`。新酷音仍由 Fcitx 5 處理；組字、提示、候選字、反白與翻頁動畫由 QML 繪製。候選視窗不接收鍵盤焦點，因此數字選字與輸入法快捷鍵仍交給原應用與 Fcitx。

## 模組

| 模組 | 可重用介面 |
| --- | --- |
| `services/JsonProcessService.qml` | `command`、`enabled`、`retryInterval`、`running`、`error`；`send(object)`、`messageReceived(object)`、`disconnected()`。以逐行 JSON 和 stdin/stdout 連接外部程式，退出後重試。 |
| `services/InputMethodService.qml` | `connected`、`visible`、`preedit`、`auxiliary`、`candidates`、`selectedIndex`、`hasPrevious`、`hasNext`、`layoutHint`、`cursorPosition`；`select(index)`、`previousPage()`、`nextPage()`。 |
| `components/PopupPlacement.qml` | 輸入螢幕尺寸、浮窗尺寸與游標座標；輸出 `x`、`y`。右側收邊、底部向上展開，缺座標時置於底部中央。可供 tooltip、選單等浮窗使用。 |
| `components/TextButton.qml` | 繼承 `InteractiveSurface`；增加 `text` 與 `textColor`。 |
| `inputmethod/CompositionText.qml` | `theme`、`composition`；支援中文文字與換行。 |
| `inputmethod/CandidateRow.qml` | `theme`、`candidate: {label, text, selectable}`、`selected`；沿用 `clicked()`。 |
| `inputmethod/CandidateList.qml` | `theme`、`candidates`、`selectedIndex`、`horizontal`、`maximumWidth`；`candidateSelected(index)`、`pageRequested(direction)`。 |
| `inputmethod/CandidatePanel.qml` | `theme`、`inputMethod`、`maximumWidth`；組裝玻璃底板、組字區、候選清單及翻頁按鈕，可獨立嵌入其他視窗。 |
| `InputMethodWindow.qml` | `theme`、`inputMethod`、`compositor`；選擇螢幕並建立不搶焦點的 layer-shell 浮窗。 |

所有視覺參數位於 `Style.qml` 的 `inputMethod`。預設中文使用 Noto Sans CJK TC、20px，直排；設定 `horizontal: true` 可以橫排，輸入法的橫排提示也會生效。螢幕座標使用 logical pixels。

選單沿用 Shell 的中央展開／收合、淡入淡出、尺寸變化與內凹反白滑動。共用 `AnimatedVisibility` 保留視窗到收合完成，`RevealSurface` 處理展開動畫，`AnimatedListView` 處理捲動與邊界回彈；三者位於 `components/`。收合時保留最後一份顯示資料，避免內容先消失。

候選清單最多顯示 `maxVisibleRows` 列，預設七列；上下滾輪捲動清單，左右滾輪翻頁。新酷音設 `CandidateLayout=Vertical`、`SelectCandidateWithArrowKey=True`，讓上下方向鍵移動選中項目、左右方向鍵翻頁；鍵盤事件仍由 Fcitx 處理。全域 PrevPage／NextPage 對應 Left／Right，PrevCandidate／NextCandidate 對應 Up／Down，保留 Tab 操作。

候選浮窗使用 `ExclusionMode.Ignore`，以螢幕原點定位，避免 Top Bar 的保留區額外加入 Y 偏移。

## 橋接與依賴

需要 `qt6-base`（Qt Core、Qt D-Bus、moc）、`gcc`、`pkgconf`、Fcitx 5 的 Kimpanel addon 和 Hyprland 的 `hyprctl`。初次啟動自動編譯 C++ 橋接至 `Quickshell.stateDir/bridges/fcitx`；原始碼或 build.sh 更新時重編。沒有 Python 套件依賴。

原生 Wayland 的文字游標定位另需與正在執行的 Hyprland commit 相符的開發標頭（`pkg-config hyprland`）。`inputmethod/hyprland-caret/` 是獨立唯讀適配模組，首次啟動編譯並載入；只新增 `hyprctl -j quickshell-caret` 查詢，不修改視窗、不攔截輸入、不讀取文字。模組在載入前檢查 runtime/header commit，一致才註冊指令。更換 Hyprland 版本後需同步更新標頭，否則模組拒絕載入。

該適配模組讀取 focused text-input 的 cursor rectangle，加上其實際 Wayland surface 的全域位置，涵蓋一般視窗及 layer-shell（例如 Launcher），不以目前 toplevel 或滑鼠位置猜測文字位置。橋接在候選框顯示時每 50ms 更新座標，隱藏時停止輪詢。

橋接註冊 `org.kde.impanel`，不替換或排隊搶佔其他已存在的 panel。Fcitx 的 Kimpanel addon 依服務可用性啟用；橋接結束時服務釋放，Fcitx 可以回到其他可用 UI。狀態以完整 JSON snapshot 傳給 QML，點選與翻頁反向傳回 Kimpanel。GUI 不由橋接繪製。

原生 Wayland 優先使用 Hyprland text-input 座標。Kimpanel 傳來的空矩形 `(0,0,0,0)` 視為缺資料。其他輸入路徑的全域游標座標直接使用；相對游標座標仍以 `hyprctl -j activewindow` 加上作用中視窗位置估算，V2 座標按傳入 scale 換算。更換 compositor 時應替換座標適配模組。

## Wayland 範圍與限制

Kimpanel 能接收到的輸入路徑會使用新候選框。部分 GTK／Qt input module 會在應用端繪製候選框，可能繞過此服務；不能宣稱所有應用已完全替換。應用的 client-side panel 行為與 native Wayland／XWayland 路徑需分別實測。

非原生 Wayland 路徑的相對座標估算仍不能保證涵蓋應用內子視窗、裝飾偏移或所有縮放組合。應用未提供 text-input cursor rectangle 時使用底部中央備援。單頁長清單以七列視口捲動呈現。

不完整實作 Kimpanel 的輸入法選單、工具列與富文字 attributes；本模組範圍是組字與候選框。輸入法切換沿用原快捷鍵／設定工具。

關閉此功能可設定入口的 `InputMethodService { enabled: false }`；不需改 Fcitx 全域設定。

Hyprland 模糊規則使用 namespace `quickshell-inputmethod`，可依現有 Launcher 規則加入：

```lua
hl.layer_rule({
    name = "quickshell-inputmethod-glass",
    match = { namespace = "^quickshell-inputmethod$" },
    blur = true,
    ignore_alpha = 0.01,
})
```

## 驗證

```sh
bash tests/run-smoke.sh
bash tests/run-bridge.sh
qs ipc call inputmethod status
hyprctl -j quickshell-caret
# 獨立預覽 2.5 秒，不連接或替換正式輸入法。
qs -p InputMethodPreview.qml
```

Smoke 測試涵蓋服務狀態映射、候選面板組裝、斷線隱藏、邊界定位與既有 launcher 回歸。橋接測試使用隔離 D-Bus 和模擬輸入法，驗證中文 snapshot、游標矩形、點選與翻頁往返，不接正式 Fcitx。

協定參考：[Fcitx 5 Kimpanel 原始碼](https://github.com/fcitx/fcitx5/blob/master/src/ui/kimpanel/kimpanel.cpp)、[Fcitx Wayland UI 限制](https://fcitx-im.org/wiki/Theme_Customization/en)。

## 選字面板翻頁

數字快捷鍵顯示在候選列內，沿用輸入法提供的標籤，不顯示頁碼；左右滾輪翻頁時，上一頁向右滑入、下一頁向左滑入。上下選取仍沿用獨立高亮與捲動動畫。

翻頁時保留已顯示的候選區高度，候選較少的頁面用底色補滿；新的第一頁內容或清空候選時重設高度。內部依候選回覆及已見頁面辨識翻頁方向；未見過的非第一頁按向後翻頁推定。

預覽 `qs -p UIPlayground.qml`；左右鍵測試翻頁。隔離測試 `bash tests/run-pages.sh`。
