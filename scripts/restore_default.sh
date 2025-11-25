#!/bin/bash

# Restore Hyprland default multi-monitor setup:
hyprctl keyword monitor eDP-1,preferred,auto,1
hyprctl keyword monitor HDMI-A-1,preferred,auto-left,1

notify-send "Restored Display Configuration" "Back to default monitor setup."
