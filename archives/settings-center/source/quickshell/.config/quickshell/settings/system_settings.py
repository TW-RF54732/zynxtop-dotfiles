"""System-owned settings. Gio uses the session's Polkit agent, never sudo."""
import hashlib, ipaddress, json, os, pathlib, re

def account(request):
    from gi.repository import Gio, GLib
    bus=Gio.bus_get_sync(Gio.BusType.SYSTEM,None)
    obj=f'/org/freedesktop/Accounts/User{os.getuid()}'
    name=request['name']; value=request['value']
    if name not in ('SetRealName','SetIconFile'): raise ValueError('未知使用者操作')
    if not isinstance(value,str) or any(ord(c)<32 for c in value): raise ValueError('名稱或路徑格式錯誤')
    if name=='SetIconFile' and not pathlib.Path(value).is_file(): raise ValueError('頭像檔案不存在')
    bus.call_sync('org.freedesktop.Accounts',obj,'org.freedesktop.Accounts.User',name,GLib.Variant('(s)',(value,)),None,Gio.DBusCallFlags.NONE,120000,None)
    return '使用者資料已更新'

def network(request, run):
    uuid=request['uuid']
    if not re.fullmatch(r'[a-fA-F0-9-]{36}',uuid): raise ValueError('請提供連線 UUID')
    props=request['properties']
    allowed={'connection.autoconnect','ipv4.method','ipv4.addresses','ipv4.gateway','ipv4.dns'}
    if set(props)-allowed: raise ValueError('未知網路屬性')
    for key,value in props.items():
        if not isinstance(value,str) or '\n' in value: raise ValueError('網路欄位格式錯誤')
        if key=='connection.autoconnect' and value not in ('yes','no'): raise ValueError('自動連線選項錯誤')
        if key=='ipv4.method' and value not in ('auto','manual','disabled'): raise ValueError('IPv4 模式錯誤')
        if key=='ipv4.addresses' and value:
            for entry in value.split(','): ipaddress.IPv4Interface(entry.strip())
        if key in ('ipv4.gateway','ipv4.dns') and value:
            for entry in value.split(','): ipaddress.IPv4Address(entry.strip())
    if 'revision' in request and network_read(uuid,run)['revision'] != request['revision']: raise ValueError('連線設定已被外部修改，請還原並重新讀取')
    if props.get('ipv4.method')=='manual' and not props.get('ipv4.addresses'): raise ValueError('手動模式需要 IPv4 位址及前綴')
    args=[]
    for key,value in props.items(): args.extend([key,value])
    run('nmcli','connection','modify','uuid',uuid,*args)
    return '網路設定已保存；重新連線後生效'

NETWORK_PROPERTIES=('connection.autoconnect','ipv4.method','ipv4.addresses','ipv4.gateway','ipv4.dns')
def network_read(uuid, run):
    if not re.fullmatch(r'[a-fA-F0-9-]{36}',uuid): raise ValueError('請提供連線 UUID')
    properties={key:run('nmcli','--escape','no','-g',key,'connection','show','uuid',uuid).replace('\n',',') for key in NETWORK_PROPERTIES}
    revision=hashlib.sha256(json.dumps(properties,sort_keys=True).encode()).hexdigest()
    return dict(ok=True,kind='network-profile',uuid=uuid,properties=properties,revision=revision)
