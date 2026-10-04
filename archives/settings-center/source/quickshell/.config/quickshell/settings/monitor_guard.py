"""Owns the confirmation deadline and commit; UI/backend exit closes its pipe."""
import fcntl, json, os, selectors, subprocess, sys, time
from backend import atomic, ROOT, STATE, read

def line():
    # Unbuffered reads keep a queued confirmation visible to select().
    data=bytearray()
    while True:
        byte=os.read(sys.stdin.fileno(),1)
        if not byte or byte==b'\n': return data.decode()
        data.extend(byte)

def commit(config):
    ROOT.mkdir(parents=True,exist_ok=True,mode=0o700)
    with open(ROOT/'.lock','a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        if 'revision' in config and read()[1]!=config['revision']: raise ValueError('設定已被外部修改，螢幕預覽已還原')
        files={ROOT/'monitors.lua':config['code']}
        if 'values' in config: files[ROOT/'settings.json']=json.dumps({'version':1,'values':config['values']},ensure_ascii=False,indent=2)+'\n'
        old={p:p.read_text() if p.exists() else None for p in files}
        written=[]
        try:
            for path,text in files.items():
                if old[path] is not None: atomic(path.with_suffix(path.suffix+'.previous'),old[path])
                atomic(path,text); written.append(path)
        except Exception:
            for path in reversed(written):
                if old[path] is None: path.unlink(missing_ok=True)
                else: atomic(path,old[path])
            raise

def main():
    config=json.loads(line())
    selector=selectors.DefaultSelector(); selector.register(sys.stdin,selectors.EVENT_READ)
    confirmed=False
    error='螢幕預覽已取消或逾時'
    wait=max(0,config['deadline']-time.time()) if 'deadline' in config else config.get('seconds',15)
    if selector.select(wait):
        if line().strip()=='confirm' and ('deadline' not in config or time.time()<config['deadline']):
            try: commit(config); confirmed=True
            except Exception as exc: error=str(exc)
    if not confirmed:
        try:
            result=subprocess.run(['hyprctl','eval',config['restore']],capture_output=True,text=True,timeout=10)
            if result.returncode or 'error' in result.stdout.lower(): raise RuntimeError(result.stderr or result.stdout)
        except Exception as exc:
            error+='；自動還原失敗：'+str(exc)
            atomic(STATE/'monitor-recovery.lua',config['restore'])
            atomic(STATE/'monitor-recovery-error.txt',error)
    try: print(json.dumps(dict(ok=confirmed,error='' if confirmed else error)),flush=True)
    except BrokenPipeError: pass
if __name__=='__main__': main()
