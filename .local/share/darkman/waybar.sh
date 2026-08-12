#!/bin/sh
# darkman hook: switch waybar between the Catppuccin Latte (light) and Mocha
# (dark) palettes, then refresh the custom/darkman indicator.
# darkman passes the current mode ("dark"/"light") as $1.
#
# style.css @imports colors.css (gitignored, created here). It's overwritten
# in place rather than symlinked so waybar's "reload_style_on_change" inotify
# watch — which follows @import targets — reliably fires on the file itself.

case "$1" in
dark)
	flavour="mocha"
	;;
light)
	flavour="latte"
	;;
*)
	echo "usage: $0 {dark|light}" >&2
	exit 1
	;;
esac

cp "$HOME/.config/waybar/colors-$flavour.css" "$HOME/.config/waybar/colors.css"

# custom/darkman re-queries `darkman get` itself on signal 8 — this refreshes
# it on every mode change, not just the waybar toggle button itself (e.g.
# `darkman set`, sunrise/sunset).
pkill -RTMIN+8 waybar
