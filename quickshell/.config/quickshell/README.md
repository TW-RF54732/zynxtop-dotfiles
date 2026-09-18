# Quickshell Desktop Shell

QML 中文候選框已接入入口，沿用共用主題、玻璃容器和服務注入。可重用模組、編譯依賴、停用方式與 Wayland 限制見 [中文候選框文件](docs/INPUT_METHOD.md)。

以 Kitty 的灰黑玻璃風格為基礎，自製搜尋、常用度排序與動畫的 Quickshell 應用程式啟動器。共用設計元件可延伸到 Top Bar 與其他面板。

Top Bar 的功能範圍、互動與預定結構記錄於 [`docs/TOP_BAR_PLAN.md`](docs/TOP_BAR_PLAN.md)。

## Top Bar

開啟 special workspace 時，工作區區域只顯示該工作區的星星圖示；關閉後恢復一般工作區數字。

Launcher 與 Top Bar 共用 Kitty `#111318` 基底及 Kitty 原生灰階，配合 Hyprland blur 與 xray。Launcher 使用 76% 不透明度，Top Bar 使用 65%，讓浮空島呈現更明顯的模糊。版面針對超寬螢幕排列為工作區、可伸展的目前視窗標題、日期時間與 Dashboard 入口；網路離線和音訊靜音時，右側會增加單色狀態圖示，不顯示應用程式品牌圖標。

| 操作 | 功能 |
| --- | --- |
| 點擊工作區 | 切換至該工作區 |
| 點擊星星圖示 | 關閉目前的 special workspace |
| 在工作區上滾動 | 切換前後已有的工作區 |
| 點擊靜音圖示 | 解除靜音 |
| 在靜音圖示上滾動 | 調整輸出音量 |
| 點擊 Dashboard 圖示 | 展開／收合 Dashboard |
| `Super + W` | 展開／收合 Dashboard，已設定於 Hyprland 快捷鍵 |

Dashboard 從螢幕上方下拉，將 Top Bar 往下推；收合時 Top Bar 回到原位。面板與 Top Bar 同寬，共用玻璃樣式，所有螢幕同步開關，桌面只保留原本 Top Bar 的空間，展開部分覆蓋在其他視窗上方，不改變視窗大小或位置。Dashboard 依序顯示系統資訊、媒體控制、音量與網路狀態、系統匣。系統區寬度限制為 660px，音量支援拖曳、滾輪與靜音切換。CPU、RAM、GPU 使用率以外、中、內三層同心半圓呈現，展開時每秒更新並平滑過渡；無法取得的數據顯示「—」。Dashboard 高度為 460px；系統區左側依序列出 CPU 頻率、溫度、執行緒數，RAM 與 swap 容量、GPU 溫度與顯存，右側為同心半圓；下方一行顯示 SSD 容量條、百分比與已用／總容量（GiB）。媒體優先顯示正在播放的 MPRIS 播放器，提供上一首、播放／暫停與下一首。系統匣支援左鍵啟用、右鍵選單、中鍵與滾輪操作。高度、間距與動畫時間可在 `Style.qml` 的 `dashboard` 區塊調整。Top Bar 的 layer-shell namespace 為 `quickshell-topbar`；若要使用與 Launcher 相同的模糊效果，需在 compositor 加入對應規則。

IPC 介面：

```sh
qs ipc call topbar toggleDashboard
qs ipc call topbar closeDashboard
```

## 視覺設計

- 灰黑半透明背景，模糊由 Hyprland 提供。
- 5px 深灰外框與 5px 外輪廓圓角。
- 反白與外框使用相同實色，避免透明圖層疊色造成色差。
- 選中列與左右外框以 5px 內凹弧線連接。
- JetBrains Mono Nerd Font Mono 等寬字體，文字以白、淺灰與暗灰區分層級。
- 無全螢幕遮罩；未輸入時只顯示輸入框，沒有 placeholder。
- 輸入框水平置中，中心位於螢幕高度的 1/3。
- 結果清單向下展開，輸入框位置固定；底部保留無分隔線的空白。
- 開關時由中央向左右攤開、收合，呈現捲軸效果。

## 依賴與啟動

需要 Quickshell、Python 3（Dashboard 系統數據）、Wayland 環境與可用的字體、圖示主題。GPU 使用率優先讀取 DRM 的 `gpu_busy_percent`，NVIDIA 使用 `nvidia-smi`（需有正常運作的驅動）。目前使用 Hyprland 提供模糊及快捷鍵；沒有 npm、Python 或外部搜尋套件依賴。

將設定放在 `~/.config/quickshell/` 後執行：

```sh
qs
```

也可以指定設定路徑：

```sh
qs -p ~/.config/quickshell
```

此儲存庫只包含 Quickshell 設定，Hyprland 的啟動、快捷鍵與模糊規則需在 compositor 設定中配置。

## 操作

| 操作 | 功能 |
| --- | --- |
| `Super + Space` | 開關 Launcher，需設定 Hyprland 快捷鍵 |
| 輸入文字 | 搜尋應用程式 |
| 空白時按 `Tab` | 顯示全部應用程式，依啟動次數排序 |
| `↑` / `↓` | 選取前後項目 |
| `Enter` | 啟動選中項目，或執行 shell 指令 |
| `Esc` / 點擊面板外 | 關閉 Launcher |
| 滑鼠移入 / 點擊項目 | 選取 / 啟動項目 |
| 滑鼠滾輪 | 捲動清單 |
| `> 指令` | 使用 `sh -lc` 執行 shell 指令 |

清單最多顯示七列，但保留完整結果，可捲動瀏覽。反白抵達可視清單底列後，再次按向下才會平滑捲動，把新選中項目帶回中央；頂部採對稱行為。接近清單末端時，捲動位置會限制在可行範圍。抵達真正的第一項或最後一項後再次操作，會短距離回彈，不會循環瞬移到另一端。

IPC 介面：

```sh
qs ipc call launcher toggle
qs ipc call -- launcher show
qs ipc call launcher hide
```

`show` 與 Quickshell CLI 子命令同名，因此以 `--` 分隔，確保呼叫 Launcher 方法。

目前使用的 Hyprland Lua 快捷鍵設定為：

```lua
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
```

## 模糊背景

Launcher 的 layer-shell namespace 為 `quickshell-launcher`。目前使用的 Hyprland Lua 規則如下；若使用不同格式的 Hyprland 設定，請以相同 namespace 建立對應的 layer rule。

```lua
hl.layer_rule({
    name = "quickshell-launcher-glass",
    match = {
        namespace = "^quickshell-launcher$",
    },
    blur = true,
    ignore_alpha = 0.01,
})
```

## 搜尋與常用度

應用程式來源是 Quickshell 的 `DesktopEntries.applications`，搜尋、排序、常用度保存與啟動由 `services/ApplicationsService.qml` 提供；Launcher 控制器與畫面透過注入的服務操作。

搜尋依序評估完全相同、名稱開頭、單字開頭、名稱包含、通用名稱、關鍵字，以及依序出現的模糊字元匹配。符合搜尋的項目再加入常用度加權：

```text
常用度分數 = min(120, log2(啟動次數 + 1) × 20)
```

文字相關性為主要依據，常用度加權有上限。空白輸入按 `Tab` 時，直接依啟動次數排序，次數相同則依名稱排序。`NoDisplay=true` 的項目會被略過。

使用次數只統計經由此 Launcher 開啟的應用程式，透過 `FileView` 與 `JsonAdapter` 保存於：

```text
Quickshell.stateDir/launcher-usage.json
```

Shell 指令不納入應用程式使用次數。

啟動應用程式時，Launcher 會先尋找同名的系統匣項目並呼叫它的啟用動作；這讓 Discord 等關閉視窗後仍常駐背景的應用可以再次顯示。找不到對應的系統匣項目時，才執行 `.desktop` 項目的啟動指令。

## 加入應用程式

Launcher 讀取標準 XDG 應用程式目錄中的 `.desktop` 項目。一般系統套件會將項目安裝到 `/usr/share/applications/`；個人程式可放在 `~/.local/share/applications/`。Flatpak 等來源需透過桌面環境的 `XDG_DATA_DIRS` 提供對應目錄。

個人項目範例：

```ini
# ~/.local/share/applications/my-app.desktop
[Desktop Entry]
Type=Application
Name=My App
Comment=My custom application
Exec=/absolute/path/to/my-app
Icon=/absolute/path/to/icon.png
Terminal=false
Categories=Utility;
```

安裝後重新開啟 Launcher 搜尋名稱，或按 `Tab` 查看全部。如果沒有出現，檢查 `.desktop` 路徑、`Name`、`Exec` 與 `NoDisplay`，並確認目前 Quickshell 行程能讀取安裝目錄；必要時重新啟動該 Quickshell 設定。

## 設計系統與檔案結構

主題與服務由入口建立一次，透過 QML 屬性注入功能模組。新增面板的介面與完整範例見 [`docs/MODULARITY.md`](docs/MODULARITY.md)。

```text
.
├── shell.qml                 # 建立共用主題、服務，組裝面板
├── Style.qml                 # 統一設計參數
├── Launcher.qml              # Launcher 視窗、焦點、IPC 與開關動畫
├── TopBar.qml                # 多螢幕視窗、版面、掃線與 Dashboard 狀態
├── components/               # 容器、文字、圖示、按鈕、分隔線、反白
├── services/                 # Compositor、音訊、網路、時鐘、應用程式
├── launcher/                 # 控制器、輸入框、清單與結果列
├── topbar/                   # 工作區、視窗標題、時鐘、狀態及 Dashboard 入口
├── examples/AudioPanel.qml   # 可複製的跨面板組裝範例
├── tests.qml                 # 不建立桌面視窗的模組 smoke 測試
└── tests/run-smoke.sh         # 隔離 runtime/state 並驗證使用次數保存
```

視覺元件不直接讀取系統服務；功能元件只接收所需的主題、服務、資料及操作訊號。各螢幕使用自己的 MonitorContext，共用同一份系統服務。

`Style.qml` 分成以下區塊：

| 區塊 | 內容 |
| --- | --- |
| `colors` | 面板、外框、分隔線、文字與文字選取色 |
| `typography` | 字體與字級 |
| `geometry` | 外框、圓角、內凹弧度、留白及共用按鈕／圖示尺寸 |
| `motion` | 動畫時間與回彈距離 |
| `launcher` | Launcher 專用尺寸、位置、圖示與顯示列數 |
| `topBar` | Top Bar 高度、邊距、文字、圖示與互動區尺寸 |

QML 的八位色碼採 `#AARRGGBB`，例如背景 `#8f292d33` 的前兩位 `8f` 控制不透明度。外框與反白共用 `colors.frame`，使用實色以維持一致的顯示結果。

動畫設定：

| 參數 | 預設值 | 用途 |
| --- | --- | --- |
| `fastDuration` | 140ms | 面板展開、收合、淡入與高度變化 |
| `selectionDuration` | 110ms | 反白等速平移 |
| `listScrollDuration` | 180ms | 清單等速捲動，將選中項目帶回中央 |
| `edgeBounceDuration` | 120ms | 邊界回彈的單程時間 |
| `edgeBounceDistance` | 18px | 邊界回彈距離 |

新面板接收入口的主題，將同一實例傳給共用元件的 `theme`：

```qml
import QtQuick
import "components"

Item {
    id: root
    required property var theme

    GlassFrame {
        theme: root.theme
        width: 300
        height: 60

        MonoText {
            theme: root.theme
            anchors.centerIn: parent
            text: "Quickshell"
        }
    }
}
```

`Separator.qml` 仍保留供其他面板使用，Launcher 底部留白沒有分隔線。`.qmlls.ini` 是 Quickshell 產生的執行期連結，已透過 `.gitignore` 排除。

## 檢查與日誌

```sh
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml *.qml components/*.qml launcher/*.qml services/*.qml topbar/*.qml examples/*.qml
bash tests/run-smoke.sh
qs log -t 30
git diff --check
```

若 `qmllint` 不在 PATH，可使用 Qt 安裝目錄內的執行檔；本機路徑為 `/usr/lib/qt6/bin/qmllint`。
