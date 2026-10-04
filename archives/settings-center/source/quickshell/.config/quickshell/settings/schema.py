"""Declarative, allowlisted settings. Defaults match the checked-in desktop."""
PAGES = [('monitors','螢幕'),('appearance','桌面外觀'),('interface','桌面介面'),
 ('input','鍵盤與滑鼠'),('ime','輸入法'),('audio','音訊'),('network','網路'),
 ('bluetooth','藍牙'),('vpn','VPN'),('notifications','通知'),('applications','預設程式與啟動'),
 ('power','電源與鎖定'),('datetime','日期與使用者'),('kitty','Kitty'),('about','關於')]
FIELDS = []
def field(page, key, label, default, low=None, high=None, choices=None, target='local'):
    FIELDS.append(dict(page=page,key=key,label=label,default=default,min=low,max=high,choices=choices,
                       type='bool' if isinstance(default,bool) else 'number' if isinstance(default,(int,float)) else 'string', target=target))
for key,label,default,low,high in [
 ('general.gaps_in','視窗內間距',5,0,100),('general.border_size','邊框寬度',0,0,20),
 ('decoration.rounding','圓角',5,0,100),('decoration.active_opacity','作用中透明度',1.0,0.1,1),
 ('decoration.inactive_opacity','非作用中透明度',1.0,0.1,1),('decoration.blur.size','模糊大小',12,1,40),
 ('decoration.blur.passes','模糊次數',3,1,10)]: field('appearance',key,label,default,low,high,target='hypr')
for key,label,default in [('decoration.blur.enabled','模糊',True),('decoration.shadow.enabled','陰影',True),('animations.enabled','動畫',True)]:
    field('appearance',key,label,default,target='hypr')
field('appearance','general.gaps_out','外間距（上 右 下 左）','15 50 20 50',target='hypr')
field('appearance','wallpaper','靜態桌布（完整路徑）','',target='wallpaper')
for key,label,default,low,high in [('typography.bodySize','內文字級',16,8,40),('topBar.height','頂端列高度',48,24,120),
 ('launcher.maxWidth','啟動器寬度',720,320,1800),('launcher.maxVisibleResults','搜尋結果列數',7,1,20),
 ('sidebar.width','側欄寬度',400,240,1000),('osd.transientTimeout','音量提示時間（毫秒）',1400,100,30000),
 ('osd.messageTimeout','狀態提示時間（毫秒）',1800,100,30000)]: field('interface',key,label,default,low,high)
field('interface','typography.family','介面字體','JetBrainsMono Nerd Font Mono')
field('interface','surfaceOpacity','玻璃透明度',0.76,0.1,1)
field('input','input.kb_layout','鍵盤配置','us',target='hypr')
field('input','input.repeat_rate','按鍵重複速度',25,1,100,target='hypr')
field('input','input.repeat_delay','按鍵重複延遲（毫秒）',600,100,2000,target='hypr')
field('input','input.sensitivity','滑鼠速度',0.0,-1,1,target='hypr')
field('input','input.follow_mouse','焦點跟隨模式',1,0,3,target='hypr')
field('input','input.touchpad.natural_scroll','觸控板自然捲動',False,target='hypr')
field('ime','inputMethod.fontFamily','候選框字體','Noto Sans CJK TC')
field('ime','inputMethod.fontSize','候選框字級',20,10,48)
field('ime','inputMethod.horizontal','水平排列',False)
field('notifications','dnd','勿擾',False)
field('notifications','notifications.defaultTimeout','顯示時間（毫秒）',16000,1000,120000)
field('notifications','notifications.laneWidth','通知列寬度',360,200,1200)
field('notifications','historyLimit','歷史保留上限',500,0,5000)
field('datetime','clock.utc','桌面時鐘使用 UTC',True)
field('datetime','clock.format','桌面時間格式','hh:mm')
for key,label,default,low,high in [('font_size','字級',12.0,6,72),('window_padding_width','內距',12,0,100),('scrollback_lines','捲動歷史行數',10000,0,1000000)]:
    field('kitty',key,label,default,low,high,target='kitty')
field('kitty','font_family','字體','Consolas',target='kitty')
field('kitty','cursor_shape','游標形狀','beam',choices=['beam','block','underline'],target='kitty')
for key,label,default in [('foreground','文字色','#ABB2BF'),('background','背景色','#111318'),('cursor','游標色','#ABB2BF')]: field('kitty',key,label,default,target='kitty')
for key,label,default in [('terminal','終端機','kitty'),('browser','瀏覽器','zen-browser'),('file_manager','檔案管理員','dolphin')]:
    field('applications','program.'+key,label+'命令',default,target='program')
for key,label,default in [('terminal','終端機快捷鍵','SUPER + Q'),('browser','瀏覽器快捷鍵','SUPER + B'),('file_manager','檔案管理員快捷鍵','SUPER + E')]:
    field('input','bind.'+key,label,default,target='bind')
field('power','idle.seconds','閒置鎖定秒數（0 為停用；下次登入生效）',0,0,86400,target='idle')
BY_KEY = {f['key']:f for f in FIELDS}
