# Top Bar 現行規格與結構

本文件記錄目前實作；模組化保留現有畫面與操作。較早的視覺比較保留於 `topbar-concepts.svg`，不作為現行版面規格。

## 版面與視覺

- 每個螢幕建立一個透明 layer-shell 視窗，內含置中的單一玻璃長條。
- 長條高度 48px、最大寬度 2200px，左右邊距 24px、頂部邊距 10px、底部預留 8px；收合時視窗高度與 exclusive zone 為 66px；Dashboard 展開時增加面板視窗高度與間距，exclusive zone 固定為 66px。
- 使用 Kitty `#111318` 衍生的 65% 不透明深色背景、1px 低對比邊框、5px 圓角；模糊與 xray 由 compositor 提供。
- 左側平時顯示該螢幕的正數工作區；開啟 special workspace 時，只顯示該工作區的星星圖示；中央為目前聚焦且屬於該螢幕的視窗標題；右側依序為日期時間、異常狀態及 Dashboard 入口。
- 視窗標題相對整條 Bar 置中，依左右區塊中較寬者限制可用寬度。過長時單行省略，沒有標題時隱藏。
- 日期與時間維持右側資訊群組，並非螢幕正中央。日期格式為 `ddd  MM/dd`，24 小時時間格式為 `hh:mm`；沿用現有 UTC 時間轉換。
- 日間 06:00–17:59 顯示太陽，其餘顯示月亮。只使用共用 MonoIcon，不顯示應用程式品牌圖示。
- 斷網及靜音才顯示對應圖示；恢復正常或後端不可用時不保留空位。
- 目前工作區以共用 frame 色、30% 透明的選擇方塊反白，切換時方塊水平滑行；Dashboard 開啟狀態使用共用 frame 色反白，不新增 hover 或循環動畫。
- 工作區變更時，底部執行一次方向掃線，維持 400ms 與既有 easing。

## 操作

| 元件 | 點擊 | 滾輪 |
| --- | --- | --- |
| 工作區 | 切換工作區 | 切換前後已有工作區 |
| 視窗標題 | 無 | 無 |
| 日期時間 | 無 | 無 |
| 離線提示 | 無 | 無 |
| 靜音提示 | 解除靜音 | 每次調整 5% 輸出音量，限制在 0–100% |
| Dashboard 入口 | 切換共用開關狀態 | 無 |

Dashboard 使用同寬玻璃容器，預設高度 280px，間距 8px，於 260ms 內從上方下拉並將 Bar 往下推；收合時反向播放。面板與視窗保持固定尺寸，只以垂直位移播放進出動畫；滑鼠輸入範圍隨可見高度調整，exclusive zone 維持原本 Top Bar 的高度；展開部分覆蓋其他視窗，不推動桌面版面。面板目前留白，內容由 `Dashboard.qml` 擴充，尺寸及動畫由 `Style.qml` 的 `dashboard` 區塊設定。

保留 `quickshell-topbar` namespace，以及以下 IPC：

```sh
qs ipc call topbar toggleDashboard
qs ipc call topbar closeDashboard
```

Bar 不取得鍵盤焦點。全螢幕顯示規則由 compositor 決定，目前沒有自動隱藏動畫。

## 模組職責

- `shell.qml` 建立共用 Style、CompositorService、AudioService、NetworkService、ClockService 及 ApplicationsService，注入各面板。
- `TopBar.qml` 建立每個螢幕的視窗與 MonitorContext，處理版面、工作區掃線、IPC 與共用 Dashboard 狀態。
- `topbar/` 元件接受主題、服務／資料，只負責呈現與最小互動，不直接匯入系統後端。
- `services/` 集中包裝 Hyprland、Networking、Pipewire 與 SystemClock；Dashboard 可重用相同服務。
- `components/` 提供 GlassFrame、MonoText、MonoIcon、Separator、InteractiveSurface 與 IconButton，統一外觀與操作介面。
- `Style.qml` 集中現有顏色、尺寸與動畫；Top Bar 細框與 Launcher 厚框仍保留各自的設計參數。

跨面板組裝及服務介面見 [`MODULARITY.md`](MODULARITY.md)。

## 驗收

- 重構前後外觀、位置、尺寸、時間格式與操作相同。
- 多螢幕工作區／視窗資訊仍以各螢幕 MonitorContext 為準；狀態服務只有一份。
- 長標題不與右側資訊群組重疊，空標題或正常系統狀態沒有 placeholder。
- 靜音及離線提示隨實際狀態更新，音訊後端切換時追蹤新的預設 sink。
- Dashboard 狀態在所有螢幕同步，IPC 名稱及 namespace 維持不變。
- Launcher 與 Top Bar 可一起載入，沒有新的 QML 錯誤或焦點衝突。
