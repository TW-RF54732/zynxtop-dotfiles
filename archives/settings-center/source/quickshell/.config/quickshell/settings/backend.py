#!/usr/bin/env python3
"""Line-oriented JSON settings transport. No shell execution or secret persistence."""
import contextlib, fcntl, hashlib, json, math, os, pathlib, platform, re, shutil, subprocess, sys, tempfile, time
from schema import FIELDS, BY_KEY, PAGES
CONFIG = pathlib.Path(os.environ.get('XDG_CONFIG_HOME', pathlib.Path.home()/'.config'))
ROOT = CONFIG/'settings-center'
STATE = pathlib.Path(os.environ.get('XDG_STATE_HOME', pathlib.Path.home()/'.local/state'))/'settings-center'

def run(*argv, timeout=15):
    result = subprocess.run(argv, text=True, capture_output=True, timeout=timeout)
    if result.returncode: raise ValueError(result.stderr.strip() or result.stdout.strip() or f'{argv[0]} 執行失敗')
    return result.stdout.strip()

def atomic(path, data):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if path.is_symlink(): raise ValueError('拒絕覆寫設定連結：'+str(path))
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix='.settings-')
    try:
        with os.fdopen(fd,'w') as stream:
            stream.write(data); stream.flush(); os.fsync(stream.fileno())
        os.replace(temp,path)
    finally:
        if os.path.exists(temp): os.unlink(temp)

def read():
    path = ROOT/'settings.json'
    raw = path.read_bytes() if path.exists() else b''
    data = json.loads(raw) if raw else {'version':1,'values':{}}
    if data.get('version') != 1 or not isinstance(data.get('values'),dict): raise ValueError('設定檔格式錯誤；請還原 settings.json.previous')
    for key,value in data['values'].items(): validate(key,value)
    fingerprint = raw
    for path in (ROOT/'hyprland.lua', ROOT/'monitors.lua', ROOT/'kitty.conf', CONFIG/'hypr/hyprland.lua', CONFIG/'kitty/kitty.conf'):
        if path.exists(): fingerprint += str(path).encode() + path.read_bytes()
    return data, hashlib.sha256(fingerprint).hexdigest()

def validate(key, value):
    if key == 'monitors':
        if not isinstance(value,list): raise ValueError('螢幕設定格式錯誤')
        outputs=[]
        for monitor in value:
            validate_monitor(monitor)
            outputs.append(monitor['output'])
        if len(set(outputs)) != len(outputs): raise ValueError('螢幕重複')
        return
    if key not in BY_KEY: raise ValueError('不支援的設定：'+key)
    f = BY_KEY[key]
    if f['type']=='bool' and type(value) is not bool: raise ValueError(f['label']+' 必須為布林值')
    if f['type']=='number':
        if type(value) not in (int,float) or not math.isfinite(value) or not f['min'] <= value <= f['max']: raise ValueError(f['label']+' 超出範圍')
        if type(f['default']) is int and int(value)!=value: raise ValueError(f['label']+' 必須為整數')
    if f['type']=='string':
        if not isinstance(value,str) or len(value)>4096 or any(ord(c)<32 for c in value): raise ValueError(f['label']+' 格式錯誤')
        if f['choices'] and value not in f['choices']: raise ValueError('無效選項')
        if key in ('foreground','background','cursor') and not re.fullmatch(r'#[0-9a-fA-F]{6}',value): raise ValueError('請使用 #RRGGBB')
        if key=='general.gaps_out' and not re.fullmatch(r'\d{1,3}( \d{1,3}){3}',value): raise ValueError('請填入四個 0–999 的整數')
        if key=='input.kb_layout' and not re.fullmatch(r'[A-Za-z0-9_,+-]+',value): raise ValueError('鍵盤配置格式錯誤')
        if key=='wallpaper' and any(c in value for c in ('{','}',',')): raise ValueError('桌布路徑不可包含逗號或大括號')
        if key.startswith('bind.') and not re.fullmatch(r'(SUPER|CTRL|ALT|SHIFT)( \+ (SUPER|CTRL|ALT|SHIFT))* \+ [A-Za-z0-9]+',value): raise ValueError('快捷鍵格式：SUPER + SHIFT + B')

def lua(value):
    if isinstance(value,dict): return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in value.items())+'}'
    if isinstance(value,list): return '{'+','.join(lua(v) for v in value)+'}'
    if isinstance(value,bool): return 'true' if value else 'false'
    if isinstance(value,str): return '"'+''.join('\\%03d'%b if b<32 or b>=127 or b in (34,92) else chr(b) for b in value.encode())+'"'
    return str(value)

def hypr_config(values):
    tree={}
    for key,value in values.items():
        if key == 'monitors' or BY_KEY[key]['target']!='hypr': continue
        if key=='general.gaps_out': value=dict(zip(('top','right','bottom','left'),map(int,value.split())))
        node=tree
        parts=key.split('.')
        for part in parts[:-1]: node=node.setdefault(part,{})
        node[parts[-1]]=value
        # Binding changes are emitted after normal modules, and survive reloads.
    code='hl.config('+lua(tree)+')\n' if tree else '-- No local overrides\n'
    for app in ('terminal','browser','file_manager'):
        key='bind.'+app
        if key in values:
            code+='hl.unbind('+lua(BY_KEY[key]['default'])+')\n'
    for app in ('terminal','browser','file_manager'):
        key='bind.'+app
        if key in values:
            command=values.get('program.'+app,BY_KEY['program.'+app]['default'])
            code+='hl.bind('+lua(values[key])+', hl.dsp.exec_cmd('+lua(command)+'))\n'
    return code

def generated(values):
    files={ROOT/'hyprland.lua':hypr_config(values), ROOT/'kitty.conf': ''.join(f'{k} {v}\n' for k,v in values.items() if k != 'monitors' and BY_KEY[k]['target']=='kitty')}
    programs={k.split('.')[1]:v for k,v in values.items() if k != 'monitors' and BY_KEY[k]['target']=='program'}
    files[ROOT/'monitors.lua']=''.join('hl.monitor('+lua(m)+')\n' for m in sorted(values.get('monitors',[]),key=lambda m:m.get('disabled',False)))
    files[ROOT/'programs.lua']='return '+lua(programs)+'\n'
    path=values.get('wallpaper','')
    files[ROOT/'hyprpaper.conf']=('wallpaper {\n    monitor =\n    path = '+path+'\n    fit_mode = cover\n}\nsplash = false\nipc = true\n') if path else ''
    return files

def capabilities():
    result={tool:bool(shutil.which(tool)) for tool in ['hyprctl','nmcli','bluetoothctl','wpctl','pavucontrol','fcitx5','fcitx5-configtool','hyprpaper','timedatectl','brightnessctl','powerprofilesctl','loginctl','hyprlock','nmtui','surfshark','xdg-mime','hypridle']}
    result['hyprland']=False
    if result['hyprctl']:
        try: result['hyprland']=isinstance(json.loads(run('hyprctl','-j','monitors')),list)
        except Exception: pass
    for key,argv in {'nmcli':('nmcli','general','status'), 'bluetoothctl':('bluetoothctl','show'), 'hypridle':('hypridle','--version'), 'powerprofilesctl':('powerprofilesctl','list'), 'brightnessctl':('brightnessctl','get')}.items():
        if result.get(key):
            try: run(*argv,timeout=3)
            except Exception: result[key]=False
    try:
        from gi.repository import Gio
        bus=Gio.bus_get_sync(Gio.BusType.SYSTEM,None)
        from gi.repository import GLib
        owners=bus.call_sync('org.freedesktop.DBus','/org/freedesktop/DBus','org.freedesktop.DBus','ListActivatableNames',None,GLib.VariantType('(as)'),Gio.DBusCallFlags.NONE,3000,None).unpack()[0]
        result['accounts']='org.freedesktop.Accounts' in owners
    except Exception: result['accounts']=False
    return result

def snapshot():
    data,revision=read(); values={f['key']:f['default'] for f in FIELDS}; caps=capabilities()
    unavailable=[]
    if caps['hyprland']:
        for f in FIELDS:
            if f['target']!='hypr': continue
            try:
                option=json.loads(run('hyprctl','-j','getoption',f['key']))
                val=next(option[k] for k in ('bool','int','float','str','css') if k in option)
                values[f['key']]=bool(val) if f['type']=='bool' else val
            except Exception: unavailable.append(f['key'])
    # Read the selected Kitty base without touching its Stow symlink.
    kitty=CONFIG/'kitty/kitty.conf'
    if kitty.exists():
        for line in kitty.read_text().splitlines():
            parts=line.strip().split(None,1)
            if len(parts)==2 and parts[0] in BY_KEY and BY_KEY[parts[0]]['target']=='kitty':
                key,val=parts
                try:
                    f=BY_KEY[key]
                    value=float(val) if f['type']=='number' else val
                    validate(key,value); values[key]=value
                except ValueError: pass
    values.update(data['values'])
    desktop_id=hashlib.md5(str(CONFIG/'quickshell/shell.qml').encode()).hexdigest()
    wireguard_path=STATE.parent/'quickshell/by-shell'/desktop_id/'wireguard-profiles.json'
    return dict(ok=True,kind='snapshot',wireguardPath=str(wireguard_path),fields=FIELDS,pages=[dict(id=k,label=v) for k,v in PAGES],values=values,overrides=data['values'],revision=revision,capabilities=caps,unavailable=unavailable)

def validate_bindings(values,previous):
    def canonical(value): return frozenset(part.strip().upper() for part in value.split('+'))
    selected={app:values.get('bind.'+app,BY_KEY['bind.'+app]['default']) for app in ('terminal','browser','file_manager')}
    if len({canonical(v) for v in selected.values()})!=len(selected): raise ValueError('常用應用快捷鍵互相衝突')
    binds=json.loads(run('hyprctl','-j','binds'))
    old={canonical(previous.get('bind.'+app,BY_KEY['bind.'+app]['default'])) for app in selected}
    for bind in binds:
        mask=bind.get('modmask',0)
        parts=[name for bit,name in [(64,'SUPER'),(4,'CTRL'),(8,'ALT'),(1,'SHIFT')] if mask & bit]
        parts.append(str(bind.get('key','')).upper())
        combo=frozenset(parts)
        if combo not in old and any(combo==canonical(v) for v in selected.values()): raise ValueError('快捷鍵與現有 Hyprland 綁定衝突')

def apply(request):
    if GUARD and GUARD.poll() is None: raise ValueError('請先確認或取消螢幕預覽')
    ROOT.mkdir(parents=True,exist_ok=True,mode=0o700)
    with open(ROOT/'.lock','a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        old,revision=read()
        if request.get('revision')!=revision: raise ValueError('設定已被外部修改，請重新載入後再套用')
        changes=request.get('changes',{}); values=dict(old['values'])
        for key,value in changes.items():
            if key not in BY_KEY: raise ValueError('未知設定；螢幕必須使用確認流程')
            if value is None: values.pop(key,None)
            else: validate(key,value); values[key]=value
        needs_hypr=any(BY_KEY[k]['target'] in ('hypr','bind','program') for k in changes)
        if needs_hypr and not capabilities()['hyprland']: raise ValueError('無法連線 Hyprland，未保存變更')
        if 'wallpaper' in changes and values.get('wallpaper') and not pathlib.Path(values['wallpaper']).is_file(): raise ValueError('桌布檔案不存在')
        if 'idle.seconds' in changes and values.get('idle.seconds') and not (shutil.which('hypridle') and shutil.which('hyprlock')): raise ValueError('需要 hypridle 與 hyprlock')
        if any(k.startswith('bind.') for k in changes): validate_bindings(values,old['values'])
        files=generated(values); files[ROOT/'settings.json']=json.dumps(dict(version=1,values=values),ensure_ascii=False,indent=2)+'\n'
        for p in files:
            if p.is_symlink() or any(parent.is_symlink() for parent in p.parents if parent != CONFIG): raise ValueError('本機設定目錄不可為符號連結')
        backups={p:p.read_text() if p.exists() else None for p in files}
        written=[]
        try:
            for p,text in files.items():
                if p.name=='settings.json': continue
                atomic(p,text); written.append(p)
            if needs_hypr:
                output=run('hyprctl','reload')
                errors=run('hyprctl','configerrors')
                if errors.strip() not in ('','ok'): raise ValueError(errors)
            if 'wallpaper' in changes:
                path=values.get('wallpaper','')
                if path: run('hyprctl','hyprpaper','wallpaper',','+path+',cover')
            atomic(ROOT/'settings.json',files[ROOT/'settings.json']); written.append(ROOT/'settings.json')
            if backups[ROOT/'settings.json'] is not None: atomic(ROOT/'settings.json.previous',backups[ROOT/'settings.json'])
        except Exception:
            for p in reversed(written):
                text=backups[p]
                if text is None: p.unlink(missing_ok=True)
                else: atomic(p,text)
            if needs_hypr:
                with contextlib.suppress(Exception): run('hyprctl','reload')
            raise
    return snapshot()

def inspect(topic):
    if topic=='user':
        import pwd
        user=pwd.getpwuid(os.getuid())
        return user.pw_name+'\n'+user.pw_gecos.split(',')[0]+'\n'+user.pw_dir
    if topic=='autostart':
        return '\n'.join(p.name for p in (CONFIG/'autostart').glob('*.desktop')) or '尚無本機登入啟動項目'
    if topic=='about':
        parts=[platform.platform(),pathlib.Path('/etc/os-release').read_text()]
        for argv in [('hyprctl','version'),('qs','--version'),('lscpu',)]:
            with contextlib.suppress(Exception): parts.append(run(*argv))
        return '\n'.join(parts)
    commands={'network':['nmcli','device','status'], 'connections':['nmcli','-f','NAME,UUID,TYPE,AUTOCONNECT','connection','show'],
      'wifi':['nmcli','-f','IN-USE,SSID,SIGNAL,SECURITY','device','wifi','list','--rescan','yes'],
      'bluetooth':['bluetoothctl','devices'], 'datetime':['timedatectl','status'],
      'power':['loginctl','show-session','self','-p','Type','-p','State'], 'ime':['fcitx5-remote'],
      'monitors':['hyprctl','-j','monitors','all'], 'audio':['wpctl','status']}
    if topic not in commands: raise ValueError('未知查詢')
    return run(*commands[topic])

def action(req):
    name=req['name']; arg=str(req.get('arg',''))
    if '\x00' in arg or '\n' in arg or arg.startswith('-'): raise ValueError('參數格式錯誤')
    fixed={'wifi-on':['nmcli','radio','wifi','on'],'wifi-off':['nmcli','radio','wifi','off'],
      'bluetooth-on':['bluetoothctl','power','on'],'bluetooth-off':['bluetoothctl','power','off'],
      'ntp-on':['timedatectl','set-ntp','true'],'ntp-off':['timedatectl','set-ntp','false'],
      'lock':['loginctl','lock-session'],'suspend':['systemctl','suspend']}
    args={'disconnect':['nmcli','device','disconnect'], 'forget':['nmcli','connection','delete','uuid'],
      'connect':['nmcli','connection','up','uuid'], 'timezone':['timedatectl','set-timezone'],
      'time':['timedatectl','set-time'], 'pair':['bluetoothctl','pair'], 'bt-connect':['bluetoothctl','connect'],
      'bt-disconnect':['bluetoothctl','disconnect'], 'bt-remove':['bluetoothctl','remove'],
      'profile':['powerprofilesctl','set'], 'brightness':['brightnessctl','set']}
    if name in fixed: return run(*fixed[name])
    if name in args: return run(*args[name],arg)
    if name=='wifi-connect':
        # nmcli --ask reads the secret from stdin; never return its captured output.
        password=req.get('password','')
        if '\n' in password or '\r' in password: raise ValueError('密碼格式錯誤')
        try:
            result=subprocess.run(['nmcli','--ask','device','wifi','connect',arg],input=password+'\n',text=True,capture_output=True,timeout=45)
        except subprocess.TimeoutExpired:
            raise ValueError('Wi-Fi 連線逾時；原有連線與密碼未寫入設定檔') from None
        if result.returncode: raise ValueError('Wi-Fi 連線失敗；請檢查密碼、訊號與 NetworkManager 授權')
        return 'Wi-Fi 已連線'
    raise ValueError('未知操作')

def validate_monitor(m):
    if not isinstance(m,dict) or not isinstance(m.get('output'),str) or not m['output'] or any(ord(c)<32 for c in m['output']): raise ValueError('螢幕名稱格式錯誤')
    if set(m)-{'output','mode','position','scale','transform','disabled'}: raise ValueError('未知螢幕屬性')
    if type(m.get('disabled',False)) is not bool: raise ValueError('無效的啟停值')
    mode=m.get('mode','preferred')
    if not isinstance(mode,str) or not re.fullmatch(r'(preferred|[1-9][0-9]*x[1-9][0-9]*(@[1-9][0-9]*(\.[0-9]+)?)?)',mode): raise ValueError('解析度格式錯誤')
    position=m.get('position','auto')
    if not isinstance(position,str) or not re.fullmatch(r'(auto|-?[0-9]+x-?[0-9]+)',position): raise ValueError('位置格式錯誤')
    if type(m.get('scale',1)) not in (int,float) or not 0.5<=m.get('scale',1)<=4: raise ValueError('縮放超出範圍')
    if type(m.get('transform',0)) is not int or not 0<=m.get('transform',0)<=7: raise ValueError('方向必須為 0–7')

GUARD=None
PENDING=None

def monitors(req):
    global GUARD,PENDING
    if req['op']=='monitor-cancel':
        if GUARD and GUARD.poll() is None: GUARD.stdin.close(); GUARD.wait(timeout=12)
        GUARD=None; PENDING=None
        return dict(ok=True,kind='monitor-cancelled',text='已還原螢幕')
    if req['op']=='monitor-confirm':
        if not GUARD or GUARD.poll() is not None: raise ValueError('預覽已逾時，螢幕已還原')
        _,revision=read()
        if revision!=PENDING['revision']: raise ValueError('設定已變動，請取消預覽')
        GUARD.stdin.write('confirm\n'); GUARD.stdin.flush(); GUARD.stdin.close(); GUARD.wait(timeout=12)
        result=json.loads(GUARD.stdout.read())
        if not result['ok']: raise ValueError(result['error'])
        GUARD=None; PENDING=None
        result=snapshot(); result['text']='螢幕設定已保存'; return result
    if GUARD and GUARD.poll() is None: raise ValueError('請先確認或取消目前預覽')
    current=json.loads(run('hyprctl','-j','monitors','all'))
    proposed=req['monitors']
    if not isinstance(proposed,list) or not proposed: raise ValueError('螢幕清單不可為空')
    names={m['name'] for m in current}
    if len(proposed)!=len(names) or {m.get('output') for m in proposed}!=names: raise ValueError('裝置已變更，請重新載入全部螢幕')
    if all(m.get('disabled',False) for m in proposed): raise ValueError('不能停用最後一個螢幕')
    for m in proposed: validate_monitor(m)
    restore=[]
    for m in current:
        restore.append(dict(output=m['name'],disabled=m.get('disabled',False),mode='preferred' if m.get('disabled') else f"{m['width']}x{m['height']}@{m['refreshRate']}",position=f"{m['x']}x{m['y']}",scale=m['scale'],transform=m.get('transform',0)))
    old,revision=read()
    persisted={m['output']:m for m in old['values'].get('monitors',[])}
    # Persist only displays edited by the user, retaining earlier overrides.
    for m in proposed:
        before=next(item for item in restore if item['output']==m['output'])
        if m != before: persisted[m['output']]=m
    values=dict(old['values'])
    values['monitors']=list(persisted.values())
    code=''.join('hl.monitor('+lua(m)+')\n' for m in sorted(proposed,key=lambda m:m.get('disabled',False)))
    saved_code=generated(values)[ROOT/'monitors.lua']
    deadline=time.time()+15
    restore_code=''.join('hl.monitor('+lua(m)+')\n' for m in sorted(restore,key=lambda m:m['disabled']))
    GUARD=subprocess.Popen([sys.executable,"-B",str(pathlib.Path(__file__).with_name('monitor_guard.py'))],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True,start_new_session=True)
    GUARD.stdin.write(json.dumps(dict(restore=restore_code,code=saved_code,values=values,revision=revision,deadline=deadline))+'\n'); GUARD.stdin.flush()
    PENDING=dict(code=code,revision=read()[1])
    try:
        result=run('hyprctl','eval',code)
        if 'error' in result.lower(): raise ValueError(result)
    except Exception:
        GUARD.stdin.close(); GUARD.wait(timeout=12); GUARD=None; PENDING=None
        raise
    return dict(ok=True,kind='preview',deadline=deadline,text='請在 15 秒內確認，否則自動還原')

def dispatch(req):
    op=req.get('op')
    if op in ('monitor-preview','monitor-confirm','monitor-cancel'): return monitors(req)
    if op=='read': return snapshot()
    if op=='revision': return dict(ok=True,kind='revision',revision=read()[1])
    if op=='apply': return apply(req)
    if op=='inspect': return dict(ok=True,kind='info',text=inspect(req['topic']))
    if op=='account':
        from system_settings import account
        return dict(ok=True,kind='result',text=account(req))
    if op=='network-read':
        from system_settings import network_read
        return network_read(req['uuid'],run)
    if op=='network-save':
        from system_settings import network
        return dict(ok=True,kind='result',text=network(req,run),resetDraft=True)
    if op=='default-app':
        desktop=req['desktop']; mime=req['mime']
        if not re.fullmatch(r'[A-Za-z0-9_.+-]+\.desktop',desktop) or not re.fullmatch(r'[A-Za-z0-9.+_-]+/[A-Za-z0-9.+_-]+',mime): raise ValueError('Desktop ID 或 MIME 格式錯誤')
        run('xdg-mime','default',desktop,mime)
        return dict(ok=True,kind='result',text='預設程式已更新')
    if op in ('autostart','autostart-remove'):
        name=req['name']
        if not re.fullmatch(r'[A-Za-z0-9_-]{1,64}',name): raise ValueError('名稱只接受英數字、底線與連字號')
        path=CONFIG/'autostart'/('settings-center-'+name+'.desktop')
        if op=='autostart-remove': path.unlink(missing_ok=True)
        else:
            command=req.get('command','')
            if not command or any(ord(c)<32 for c in command): raise ValueError('命令不可為空或包含換行')
            atomic(path,'[Desktop Entry]\nType=Application\nName='+name+'\nExec='+command+'\nHidden='+('false' if req['enabled'] else 'true')+'\n')
        return dict(ok=True,kind='result',text='登入啟動項目已更新；下次登入生效')
    if op=='action': return dict(ok=True,kind='result',text=action(req) or '操作完成')
    raise ValueError('未知請求')

if __name__=='__main__':
    for line in sys.stdin:
        try: response=dispatch(json.loads(line))
        except Exception as error: response=dict(ok=False,error=str(error))
        print(json.dumps(response,ensure_ascii=False),flush=True)

    if GUARD and GUARD.poll() is None: GUARD.stdin.close()
