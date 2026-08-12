#!/bin/sh
# waybar custom/darkman module: report the current darkman mode as JSON
# (text/class/tooltip). Re-run on click (toggles the mode) and whenever
# ~/.local/share/darkman/waybar.sh signals waybar after any other mode
# change (sunrise/sunset, `darkman set`, etc).

mode=$(darkman get)

case "$mode" in
dark)
	icon="󰖔"
	tooltip="Dark mode — click to switch to light"
	;;
light)
	icon="󰖙"
	tooltip="Light mode — click to switch to dark"
	;;
*)
	icon="?"
	mode="unknown"
	tooltip="darkman: unable to determine mode"
	;;
esac

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$icon" "$mode" "$tooltip"
