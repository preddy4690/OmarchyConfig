#!/bin/bash
# Re-enable DPMS and re-apply monitor configuration after wakeup from standby.
# monitor-watch.sh handles external monitors that reconnect later (Thunderbolt/USB-C).

sleep 2
hyprctl dispatch dpms on
hyprctl keyword monitor "eDP-1, 2560x1600@165, 1296x864, 1.666667"
hyprctl keyword monitor "DP-9, 3440x1440@119.99, 2064x0, 1.666667"
hyprctl keyword monitor "DP-10, 3440x1440@119.99, 0x0, 1.666667"
