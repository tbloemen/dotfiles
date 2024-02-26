#!/usr/bin/bash

function run {
    if ! pgrep "$1" ; then
        "$@"&
    fi
}

sleep 2

# Specific to current laptop (HP Pavillion) and port (HDMI)
if xrandr | grep -q "HDMI-1-0 connected" ; then
    xrandr --output eDP --primary --mode 1920x1080 --pos 2560x691 --rotate normal --output HDMI-1-0 --mode 2560x1080 --pos 0x0 --rotate normal
fi