# 模組與面板組裝

使用 QML 直接組裝；主題和系統服務由 `shell.qml` 建立一次，再注入面板。新增面板不需要自行讀取 Pipewire、Networking 或 Hyprland，也不需要複製現有樣式。

## 職責與依賴

| 層級 | 職責 | 可以依賴 |
| --- | --- | --- |
| `Style.qml` | 顏色、字體、共用尺寸、動畫與各面板尺寸 | QtQuick |
| `components/` | 通用視覺與互動元件 | QtQuick、注入的主題 |
| `services/` | 系統狀態、系統操作及應用程式搜尋 | Quickshell 系統 API |
| `launcher/`、`topbar/` | 功能控制器與畫面 | 共用元件、注入的服務／資料 |
| `Launcher.qml`、`TopBar.qml` | 視窗、面板版面、焦點、IPC | 功能元件與注入的服務 |
| `shell.qml` | 建立主題、服務與面板 | 上述各層 |

動畫及捲動屬於畫面；搜尋和排序屬於應用程式服務；查詢、選取與關閉請求屬於 Launcher 控制器。功能元件透過屬性及訊號溝通，不讀取其他檔案內的 ID。

## 共用元件

所有元件都能接受 `theme`；`MonoIcon` 也保留不提供主題、直接指定顏色與線寬的用法。

| 元件 | 主要介面 |
| --- | --- |
| `GlassFrame` | `theme`；可覆寫 `color`、`radius`、`border`，內容放入子元件 |
| `MonoText` | `theme`、`tone`；預設 body 字級，可覆寫 Text 屬性 |
| `MonoIcon` | `name`、`theme`、`color`、`lineWidth`；支援 offline、muted、dashboard、sun、moon |
| `Separator` | `theme`、`vertical`、`thickness`、`length`；可用 anchors 指定長度 |
| `InteractiveSurface` | `theme`、`active`、`interactive`、`hoverEnabled`、`wheelEnabled`；發出 clicked、entered、wheel(event) |
| `IconButton` | 繼承 InteractiveSurface，增加 `name`、`iconSize`、`lineWidth`、`iconColor` |
| `InsetHighlight` | `theme`、`selectionOffset`、`fillColor`、`moveDuration`；呈現內凹反白 |

`interactive: false` 保留圖示但停用滑鼠操作；`enabled: false` 停用整個元件。按鈕不新增 hover 底色。只有 `wheelEnabled: true` 時接收滾輪，否則交回外層處理。

Launcher 的厚框與 Top Bar 的細框共用 GlassFrame，分別由主題提供既有尺寸及顏色。調整共用按鈕大小、圖示大小及線寬時，修改 `geometry.controlSize`、`geometry.iconSize`、`geometry.iconStrokeWidth`；Top Bar 的對應參數沿用這些值。

## 服務介面

| 服務 | 可讀狀態／操作 |
| --- | --- |
| `CompositorService` | `workspaces`、`activeWindow`、`monitorFor(screen)`、`focusWorkspace(selector)` |
| `MonitorContext` | 注入 `compositor`、`screen`；提供 `monitor`、`activeWorkspaceId`、`workspaces`、`title`、`focusWorkspace(selector)`、`stepWorkspace(direction)` |
| `AudioService` | `available`、`muted`、`volume`；`setMuted(bool)`、`setVolume(value)`、`adjustVolume(delta)` |
| `NetworkService` | `available`、`offline` |
| `ClockService` | `displayDate`、`daytime`；沿用目前 UTC 日期時間與分鐘更新 |
| `ApplicationsService` | `search(query, showAll)`、`launch(app)`、`executeCommand(command)`、`usageCount(app)` |

`search` 回傳 `{ app, rank, launches }` 陣列，沿用原排序、NoDisplay 過濾與常用度加權。`launch` 記錄使用次數，優先啟用符合的系統匣項目，再執行 desktop entry。命令由 `sh -lc` 執行，不計入使用次數。

每個螢幕建立一個 MonitorContext，系統服務仍共用同一實例。音訊後端不可用時，操作不執行且不顯示靜音狀態；網路後端不存在時不顯示離線提示。

## Launcher 元件介面

- `LauncherController` 接收 `applications`；管理 `query`、`showAll`、`results`、`selectedIndex`，提供 `reset()`、`showAllApplications()`、`activate()`，發出 `closeRequested()`。
- `SearchField` 接收 `theme`、`commandMode`，公開 `text` 與 `focusInput()`，發出關閉、啟動、顯示全部及選取移動請求。
- `ResultsList` 接收 `theme`、`results`、`selectedIndex`，提供 `moveSelection(delta)`、`positionViewAtBeginning()`、唯讀 `contentY`／`contentHeight`，發出 `selectionRequested(index)` 與 `activationRequested()`；呼叫端負責更新選取索引。
- `ResultRow` 接收 `theme`、`app`、`selected`，發出 `hovered()` 與 `activated()`。

## 新面板範例

`examples/AudioPanel.qml` 示範玻璃容器、文字、圖示按鈕與音訊服務，可直接放入新的 PanelWindow。按鈕切換靜音，滾輪以 5% 調整音量。

在入口加入 import，並使用現有主題與音訊服務：

```qml
import Quickshell
import Quickshell.Wayland
import "examples"

// 以下放入現有 ShellRoot，與 Launcher、TopBar 同層。
PanelWindow {
    anchors { bottom: true; right: true }
    implicitWidth: 300
    implicitHeight: 60
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell-audio-example"

    AudioPanel {
        anchors.fill: parent
        theme: sharedTheme
        audio: audioService
    }
}
```

新面板的 layer-shell namespace 與 compositor 模糊規則由該面板自行指定。範例預設沒有加入正式入口，Dashboard 也尚未實作。

## 檢查

```sh
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml *.qml components/*.qml launcher/*.qml services/*.qml topbar/*.qml examples/*.qml
bash tests/run-smoke.sh
git diff --check
qs log -t 30
```

Smoke 測試使用獨立設定副本（排除 qmlls 連結）、offscreen 畫面及暫存 state/runtime，避免建立桌面面板或更動正式使用次數；檢查搜尋、控制器、清單選取、長清單捲動、兩端回彈、尺寸、範例載入及 JSON 保存。隔離環境沒有 Pipewire socket 時，可能顯示連線錯誤，測試仍能驗證無音訊後端的元件載入。

Wayland 實機仍需確認焦點、點擊外部關閉、動畫、長清單捲動、多螢幕與狀態變化。`qmllint` 對 Quickshell 的 PanelWindow 可建立性與 FileViewAdapter 型別有既存警告；需配合實際 Quickshell 載入日誌判斷。
