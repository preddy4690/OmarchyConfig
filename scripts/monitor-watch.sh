#!/bin/bash
# Supervised monitor watcher — run as a systemd user service (Restart=always).
# Uses Hyprland's monitoradded event plus a 10s periodic poll as fallback,
# so missed events (e.g. after sleep) are always caught within 10 seconds.

exec python3 - <<'EOF'
import select, socket, os, subprocess, time

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
    r = subprocess.run(['hyprctl', 'monitors'], capture_output=True, text=True)
    return all(s in r.stdout for s in EXTERNAL_SERIALS)

instance = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
runtime_dir = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
sock_path = f'{runtime_dir}/hypr/{instance}/.socket2.sock'

while True:
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(sock_path)

        # On (re)connect: apply immediately if monitors are missing.
        # This catches any monitoradded events that fired while disconnected.
        if not external_monitors_ready():
            apply_monitors()

        buf = b''
        while True:
            # 10s timeout: acts as periodic poll in case events are missed
            ready = select.select([s], [], [], 10.0)
            if ready[0]:
                data = s.recv(4096)
                if not data:
                    break  # Connection closed — reconnect
                buf += data
                lines = buf.split(b'\n')
                buf = lines[-1]  # Hold incomplete last line
                for line in lines[:-1]:
                    if b'monitoradded' in line:
                        apply_monitors()
            else:
                # Periodic check — recover from any missed events
                if not external_monitors_ready():
                    apply_monitors()

        s.close()
    except Exception:
        time.sleep(1)  # Brief pause then reconnect
EOF
