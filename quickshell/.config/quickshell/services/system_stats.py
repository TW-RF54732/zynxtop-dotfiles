"""Stream Linux system usage as JSON; missing sensors stay null."""
import glob
import json
import os
import subprocess
import time


def read_number(path, scale=1):
    try:
        with open(path) as stream:
            return float(stream.read()) / scale
    except (OSError, ValueError):
        return None


def cpu_details():
    frequency = read_number('/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq', 1000000)
    temperature = None
    for monitor in glob.glob('/sys/class/hwmon/hwmon*'):
        try:
            with open(monitor + '/name') as stream:
                name = stream.read().strip()
            if name in ('coretemp', 'k10temp', 'zenpower'):
                temperature = read_number(monitor + '/temp1_input', 1000)
                break
        except OSError:
            pass
    return dict(cpuGHz=frequency, cpuTemperature=temperature, cpuThreads=os.cpu_count())


def cpu_sample():
    with open('/proc/stat') as stream:
        values = list(map(int, stream.readline().split()[1:9]))
    return sum(values), values[3] + values[4]


def gpu_sample():
    for card in sorted(glob.glob('/sys/class/drm/card[0-9]*/device')):
        try:
            with open(card + '/gpu_busy_percent') as stream:
                usage = float(stream.read())
            temperatures = glob.glob(card + '/hwmon/hwmon*/temp1_input')
            return dict(gpu=usage, gpuTemperature=read_number(temperatures[0], 1000) if temperatures else None,
                        gpuMemoryUsed=read_number(card + '/mem_info_vram_used'),
                        gpuMemoryTotal=read_number(card + '/mem_info_vram_total'))
        except (OSError, ValueError):
            pass
    try:
        result = subprocess.run(
            ['nvidia-smi', '--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total', '--format=csv,noheader,nounits'],
            capture_output=True, text=True, timeout=1, check=True)
        fields = result.stdout.splitlines()[0].split(',')
        def number(index, scale=1):
            try:
                return float(fields[index].strip()) * scale
            except (ValueError, IndexError):
                return None
        return dict(gpu=number(0), gpuTemperature=number(1),
                    gpuMemoryUsed=number(2, 1048576), gpuMemoryTotal=number(3, 1048576))
    except (OSError, ValueError, IndexError, subprocess.SubprocessError):
        return dict(gpu=None, gpuTemperature=None, gpuMemoryUsed=None, gpuMemoryTotal=None)


def sample(previous):
    current = cpu_sample()
    elapsed = current[0] - previous[0]
    cpu = 100 * (1 - (current[1] - previous[1]) / elapsed) if elapsed > 0 else None
    with open('/proc/meminfo') as stream:
        memory = {line.split(':')[0]: int(line.split()[1]) * 1024 for line in stream}
    disk = os.statvfs('/')
    total = disk.f_blocks * disk.f_frsize
    used = total - disk.f_bfree * disk.f_frsize
    return current, dict(cpu=cpu, ram=100 * (1 - memory['MemAvailable'] / memory['MemTotal']),
                        ramUsed=memory['MemTotal'] - memory['MemAvailable'],
                        ramTotal=memory['MemTotal'], swapUsed=memory.get('SwapTotal', 0) - memory.get('SwapFree', 0),
                        swapTotal=memory.get('SwapTotal', 0), diskUsed=used, diskTotal=total,
                        **cpu_details(), **gpu_sample())


if __name__ == '__main__':
    previous = cpu_sample()
    while True:
        time.sleep(1)
        try:
            previous, data = sample(previous)
            print(json.dumps(data), flush=True)
        except (OSError, ValueError, KeyError):
            print('{}', flush=True)
