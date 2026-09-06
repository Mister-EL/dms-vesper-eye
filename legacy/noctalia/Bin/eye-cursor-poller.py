#!/usr/bin/env python3
"""Cursor poller for DesktopEye.

Queries Hyprland socket1 directly (unix socket, no fork/exec per sample)
and prints "x y" only when the cursor actually moved. Polling rate adapts:
fast while the cursor moves, slower when it rests, slowest when idle long
enough for the eye to be half-closed anyway.
"""
import os
import socket
import sys
import time

FAST = 0.06      # cursor moved within the last 2s
MID = 0.20       # resting
SLOW = 0.40      # idle > 10s (eye is lidded, only needs a wake signal)


def socket_path():
    xdg = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        base = os.path.join(xdg, "hypr")
        try:
            sig = sorted(os.listdir(base))[0]
        except (OSError, IndexError):
            sys.exit(1)
    return os.path.join(xdg, "hypr", sig, ".socket.sock")


PATH = socket_path()


def query():
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.settimeout(1.0)
        s.connect(PATH)
        s.sendall(b"cursorpos")
        data = b""
        while True:
            chunk = s.recv(256)
            if not chunk:
                break
            data += chunk
        return data.decode("ascii", "ignore").strip()
    finally:
        s.close()


def main():
    last = None
    last_move = time.monotonic()
    failures = 0
    while True:
        try:
            pos = query()
            failures = 0
        except OSError:
            failures += 1
            if failures > 10:
                sys.exit(1)
            time.sleep(1.0)
            continue
        if pos and pos != last:
            last = pos
            last_move = time.monotonic()
            try:
                x, y = pos.split(",")
                print(f"{int(x.strip())} {int(y.strip())}", flush=True)
            except ValueError:
                pass
            except BrokenPipeError:
                sys.exit(0)
        if os.getppid() == 1:
            # quickshell died and we got reparented — don't linger
            sys.exit(0)
        resting = time.monotonic() - last_move
        time.sleep(FAST if resting < 2.0 else MID if resting < 10.0 else SLOW)


if __name__ == "__main__":
    main()
