hl.config({
	plugin = {
		dynamic_cursors = {

			-- 啟用外掛
			enabled = true,

			-- 設定游標行為，支援以下值：
			-- tilt    - 根據 X 軸速度傾斜游標
			-- rotate  - 根據移動方向旋轉游標
			-- stretch - 根據方向與速度拉伸游標形狀
			-- none    - 不變更游標行為
			mode = "tilt",

			-- 形狀變更所需的最小角度差（度）
			-- 數值越小越平滑，但對硬體游標的負擔越大
			threshold = 2,

			-- 適用於 mode = "rotate"
			rotate = {

				-- 用於旋轉游標的模擬指棒長度（像素）
				-- 設為實際游標大小時最為逼真
				length = 30,

				-- 套用至角度的順時針偏移量（度）
				-- 此設定會套用至所有形狀
				offset = 0.0,
			},

			-- 適用於 mode = "tilt"
			tilt = {

				-- 控制傾斜的強度；數值越低，傾斜越強
				-- 此值控制達到完全傾斜時的速度（像素／秒）
				limit = 2000,

				-- 速度與傾斜的關係，支援以下值：
				-- linear             - 使用線性函數
				-- quadratic          - 使用二次函數（最接近實際的空氣阻力）
				-- negative_quadratic - 二次函數的負值版本，感覺更為強烈
				-- 計算方式的詳細資訊請參閱 `src/mode/utils.cpp` 中的 `activation`
				activation = "negative_quadratic",

				-- 用於計算速度的時間窗口（毫秒）
				-- 數值越高，慢速移動越平滑，但延遲也越高
				window = 80,

				-- 每一側的最大傾斜角度（°）
				full = 90,
			},

			-- 適用於 mode = "stretch"
			stretch = {

				-- 控制游標的拉伸程度
				-- 此值控制達到完全拉伸時的速度（像素／秒）
				-- 完全拉伸時的長度為原始長度的兩倍
				limit = 3000,

				-- 速度與拉伸量的關係，支援以下值：
				-- linear             - 使用線性函數
				-- quadratic          - 使用二次函數
				-- negative_quadratic - 二次函數的負值版本，感覺更為強烈
				-- 計算方式的詳細資訊請參閱 `src/mode/utils.cpp` 中的 `activation`
				activation = "quadratic",

				-- 用於計算速度的時間窗口（毫秒）
				-- 數值越高，慢速移動越平滑，但延遲也越高
				window = 100,
			},

			-- 設定搖動尋找功能
			-- 搖動游標時將其放大
			shake = {

				-- 啟用搖動尋找功能
				enabled = false,

				-- 控制偵測到搖動的靈敏度
				-- 數值越低，越快偵測到搖動
				threshold = 6.0,

				-- 搖動開始後立即套用的放大倍率
				base = 4.0,
				-- 持續搖動時每秒增加的放大倍率
				speed = 4.0,
				-- 目前的搖動強度對速度的影響程度
				influence = 0.0,

				-- 游標可達到的最大放大倍率
				-- 小於 1 的值會停用此限制（例如 0）
				limit = 0.0,

				-- 搖動結束後游標維持放大的時間（毫秒）
				timeout = 2000,

				-- 搖動時是否顯示 `tilt`、`rotate` 等游標行為
				effects = false,

				-- 啟用搖動的 IPC 事件
				-- 請參閱下方的 `ipc` 區段
				ipc = false,
			},

			-- 游標放大時使用 hyprcursor 取得更高解析度的紋理
			-- 請參閱下方的 `hyprcursor` 區段
			hyprcursor = {

				-- 放大超過紋理尺寸時，使用最近鄰（像素化）縮放
				-- 即使未啟用 hyprcursor 支援，此設定也會生效
				-- 0 - 永不使用像素化縮放
				-- 1 - 沒有高解析度圖片時使用像素化縮放
				-- 2 - 一律使用像素化縮放
				nearest = 1,

				-- 啟用專用的 hyprcursor 支援
				enabled = false,

				-- 載入放大形狀時使用的解析度（像素）
				-- 請注意，載入非常高解析度的圖片會花費較長時間，也可能增加記憶體用量
				-- -1 表示使用［一般游標大小］*［shake:base 選項］
				resolution = -1,

				-- 放大用戶端游標時使用的形狀
				-- 可用名稱請參閱形狀規則的 shape-name 屬性
				-- 指定 clientside 會使用實際形狀，但畫面會像素化
				fallback = "clientside",
			},
		},
	},
})
