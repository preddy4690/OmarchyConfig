#!/bin/bash
# Long-running retry loop after resume from sleep.
# Called by the system sleep hook (/etc/systemd/system-sleep/hyprland-monitors).
# Retries for up to 2 minutes so slow Thunderbolt re-enumeration is always caught.

apply_monitors() {
    hyprctl dispatch dpms on
    hyprctl keyword monitor "eDP-1, 2560x1600@165, 1296x864, 1.666667"
    hyprctl keyword monitor "desc:LG Electronics LG ULTRAWIDE 509RMXXHA578, 3440x1440@119.99, 2064x0, 1.666667"
    hyprctl keyword monitor "desc:LG Electronics LG ULTRAWIDE 509RMAQHA576, 3440x1440@119.99, 0x0, 1.666667"
}

external_ready() {
    hyprctl monitors | grep -q "509RMXXHA578" && hyprctl monitors | grep -q "509RMAQHA576"
}

sleep 2
apply_monitors

# Retry every 5 seconds for up to 2 minutes
for i in $(seq 1 24); do
    sleep 5
    external_ready && exit 0
    apply_monitors
done
