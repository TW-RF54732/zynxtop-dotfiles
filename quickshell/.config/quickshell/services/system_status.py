"""Read OS and logind status without changing system state."""
import json
import platform
import shutil
import subprocess
import time
from pathlib import Path


def run(command):
    try:
        return subprocess.run(command, capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.SubprocessError):
        return None


def snapshot():
    release = platform.freedesktop_os_release()
    kernel = platform.release()
    uptime = int(float(Path('/proc/uptime').read_text().split()[0]))
    reboot = Path('/run/reboot-required').exists() or not Path('/usr/lib/modules', kernel).exists()
    updates = run(['pacman', '-Qu'])
    update_label = 'UNKNOWN'
    if updates and updates.returncode in (0, 1) and not updates.stderr.strip():
        count = len(updates.stdout.splitlines())
        update_label = f'{count} PENDING (LOCAL)' if count else 'NONE (LOCAL)'
    capabilities = {}
    for action, method in [('suspend', 'CanSuspend'), ('hibernate', 'CanHibernate'), ('reboot', 'CanReboot'), ('poweroff', 'CanPowerOff')]:
        result = run(['busctl', 'call', 'org.freedesktop.login1', '/org/freedesktop/login1', 'org.freedesktop.login1.Manager', method])
        capabilities[action] = bool(result and result.returncode == 0 and result.stdout.strip() in ('s "yes"', 's "challenge"'))
    capabilities['lock'] = bool(shutil.which('hyprlock'))
    return dict(osVersion=release.get('PRETTY_NAME', release.get('NAME', 'Linux')), kernel=kernel,
                uptime=uptime, updates=update_label,
                reboot='REQUIRED' if reboot else 'NOT DETECTED',
                capabilities=capabilities)


if __name__ == '__main__':
    while True:
        try:
            print(json.dumps(snapshot()), flush=True)
        except (OSError, ValueError):
            print('{}', flush=True)
        time.sleep(10)
