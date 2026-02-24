#!/bin/bash
# Event-driven monitor watcher: listens for Hyprland's monitoradded event and
# re-applies monitor config the instant an external monitor physically reconnects.
# Handles post-sleep reconnects regardless of how long they take.
# Autostarted via exec-once in autostart.conf.

exec python3 - <<'EOF'
import socket, os, subprocess, time

def apply_monitors():
    time.sleep(1)  # Brief stabilization before reconfiguring
    subprocess.run(['hyprctl', 'dispatch', 'dpms', 'on'])
    for conf in [
        'eDP-1, 2560x1600@165, 1296x864, 1.666667',
        'DP-9, 3440x1440@119.99, 2064x0, 1.666667',
        'DP-10, 3440x1440@119.99, 0x0, 1.666667',
    ]:
        subprocess.run(['hyprctl', 'keyword', 'monitor', conf])

instance = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
runtime_dir = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
sock_path = f'{runtime_dir}/hypr/{instance}/.socket2.sock'

while True:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(sock_path)
            with s.makefile('r') as f:
                for line in f:
                    if 'monitoradded' in line:
                        apply_monitors()
    except Exception:
        time.sleep(5)  # Reconnect on error (e.g. Hyprland restart)
EOF
