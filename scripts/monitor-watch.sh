#!/bin/bash
# Event-driven monitor watcher: listens for Hyprland's monitoradded event and
# re-applies monitor config the instant an external monitor physically reconnects.
# Uses desc: matching so port name changes after Thunderbolt re-enumeration don't matter.
# Autostarted via exec-once in autostart.conf.

exec python3 - <<'EOF'
import socket, os, subprocess, time

MONITORS = [
    'eDP-1, 2560x1600@165, 1296x864, 1.666667',
    'desc:LG Electronics LG ULTRAWIDE 509RMXXHA578, 3440x1440@119.99, 2064x0, 1.666667',
    'desc:LG Electronics LG ULTRAWIDE 509RMAQHA576, 3440x1440@119.99, 0x0, 1.666667',
]

EXTERNAL_SERIALS = ['509RMXXHA578', '509RMAQHA576']

def apply_monitors():
    time.sleep(1)
    subprocess.run(['hyprctl', 'dispatch', 'dpms', 'on'])
    for conf in MONITORS:
        subprocess.run(['hyprctl', 'keyword', 'monitor', conf])

def external_monitors_ready():
    result = subprocess.run(['hyprctl', 'monitors'], capture_output=True, text=True)
    return all(s in result.stdout for s in EXTERNAL_SERIALS)

instance = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
runtime_dir = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
sock_path = f'{runtime_dir}/hypr/{instance}/.socket2.sock'

while True:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(sock_path)
            # On every (re)connect check immediately — we may have missed monitoradded
            # events while the socket was disconnected (e.g. after wakeup from sleep).
            if not external_monitors_ready():
                apply_monitors()
            with s.makefile('r') as f:
                for line in f:
                    if 'monitoradded' in line:
                        apply_monitors()
    except Exception:
        time.sleep(1)  # Brief pause then reconnect — keep delay short to avoid missing events
EOF
