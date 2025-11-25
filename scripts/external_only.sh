#!/bin/bash

hyprctl keyword monitor eDP-1, disable
hyprctl keyword monitor HDMI-A-1, 2560x1080@60, auto, 1

notify-send "External Monitor Mode" "Laptop display disabled"
