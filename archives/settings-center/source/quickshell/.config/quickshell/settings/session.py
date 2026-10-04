#!/usr/bin/env python3
"""Session bridges for wallpaper, managed XDG autostarts and optional idle lock."""
import os, pathlib, subprocess, sys
from backend import CONFIG, ROOT, read

def start():
    from gi.repository import Gio
    for path in (CONFIG/'autostart').glob('settings-center-*.desktop'):
        info=Gio.DesktopAppInfo.new_from_filename(str(path))
        if info and not info.get_is_hidden(): info.launch([],None)
    try: seconds=read()[0]['values'].get('idle.seconds',0)
    except Exception: seconds=0
    if seconds:
        from backend import atomic
        config=ROOT/'hypridle.conf'
        atomic(config,'general {\n    lock_cmd = hyprlock\n}\nlistener {\n    timeout = '+str(seconds)+'\n    on-timeout = hyprlock\n}\n')
        subprocess.Popen(['hypridle','-c',str(config)],start_new_session=True)

if __name__=='__main__':
    if '--wallpaper' in sys.argv:
        override=ROOT/'hyprpaper.conf'
        config=override if override.exists() and override.stat().st_size else CONFIG/'hypr/hyprpaper.conf'
        os.execvp('hyprpaper',['hyprpaper','-c',str(config)])
    else: start()
