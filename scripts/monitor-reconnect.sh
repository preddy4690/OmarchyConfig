#!/bin/bash
# Re-enable DPMS and re-apply monitor configuration after wakeup from standby.
# Uses desc: matching so config applies even if Thunderbolt reassigns port numbers.
# monitor-watch.sh handles monitors that reconnect later than this initial attempt.

sleep 2
hyprctl dispatch dpms on
hyprctl keyword monitor "eDP-1, 2560x1600@165, 1296x864, 1.666667"
hyprctl keyword monitor "desc:LG Electronics LG ULTRAWIDE 509RMXXHA578, 3440x1440@119.99, 2064x0, 1.666667"
hyprctl keyword monitor "desc:LG Electronics LG ULTRAWIDE 509RMAQHA576, 3440x1440@119.99, 0x0, 1.666667"
