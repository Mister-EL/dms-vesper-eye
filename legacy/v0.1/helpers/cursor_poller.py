#!/usr/bin/env python3
"""Read-only Hyprland cursor/DPMS bridge. No shell, network or instance guessing."""
import argparse
import json
import math
import os
import signal
import socket
import sys
import time
from pathlib import Path


def ipc_path():
    signature = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
    runtime = os.environ.get('XDG_RUNTIME_DIR', '')
    if not signature or not runtime or '/' in signature or signature in ('.', '..'):
        raise ValueError('A specific Hyprland instance and XDG_RUNTIME_DIR are required')
    return str(Path(runtime) / 'hypr' / signature / '.socket.sock')


def query(path, command):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.settimeout(0.5)
        sock.connect(path)
        sock.sendall(command.encode('ascii'))
        chunks = bytearray()
        while True:
            block = sock.recv(8192)
            if not block:
                break
            chunks.extend(block)
            if len(chunks) > 1048576:
                raise ValueError('Oversized IPC response')
    return json.loads(chunks)


def emit(message):
    print(json.dumps(message, separators=(',', ':')), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--screen', required=True)
    parser.add_argument('--eco', action='store_true')
    parser.add_argument('--no-cursor', action='store_true')
    args = parser.parse_args()
    try:
        path = ipc_path()
    except ValueError:
        print('Vesper Eye: no explicit Hyprland instance', file=sys.stderr)
        return 2
    parent = os.getppid()
    last = None
    last_time = time.monotonic()
    last_move = 0.0
    next_monitor = 0.0
    awake = None
    failures = 0
    while os.getppid() == parent:
        now = time.monotonic()
        try:
            if now >= next_monitor:
                monitors = query(path, 'j/monitors')
                monitor = next((m for m in monitors if m.get('name') == args.screen), None)
                on = bool(monitor and monitor.get('dpmsStatus', True) and not monitor.get('disabled', False))
                if on != awake:
                    awake = on
                    emit({'awake': awake})
                next_monitor = now + 1.0
            if awake and not args.no_cursor:
                position = query(path, 'j/cursorpos')
                xy = (float(position['x']), float(position['y']))
                if not all(math.isfinite(v) for v in xy):
                    raise ValueError('Non-finite cursor position')
                if xy != last:
                    dt = max(0.016, now - last_time)
                    speed = math.hypot(xy[0] - last[0], xy[1] - last[1]) / dt if last else 0.0
                    emit({'x': xy[0], 'y': xy[1], 'speed': round(speed, 2)})
                    last = xy
                    last_move = now
                last_time = now
            failures = 0
        except (OSError, ValueError, KeyError, TypeError):
            failures += 1
            if failures >= 5:
                print('Vesper Eye: IPC unavailable; stopping bridge', file=sys.stderr)
                return 1
            time.sleep(min(2.0, 0.25 * 2 ** (failures - 1)))
            continue
        if not awake or args.no_cursor:
            time.sleep(0.5)  # monitor status only; no cursor queries while DPMS is off
        elif args.eco:
            time.sleep(1 / 60 if now - last_move < 0.75 else 0.10)
        else:
            time.sleep(1 / 60 if now - last_move < 0.75 else 0.08)
    return 0


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        sys.exit(main())
    except BrokenPipeError:
        os._exit(0)
