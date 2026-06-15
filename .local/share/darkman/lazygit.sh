#!/bin/sh
# darkman hook: point lazygit at the Catppuccin preset (lavender accent) for
# the current mode — Latte (light) / Mocha (dark).
# darkman passes the current mode ("dark"/"light") as $1.
#
# lazygit reads its config only at launch (no live reload), and merges the
# comma-separated files in $LG_CONFIG_FILE (set in hyprland.lua). That env var
# points the second file at the symlink we swap here, so every newly opened
# lazygit picks up the active flavour. Already-running instances are unaffected.

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

theme_src="$HOME/.config/lazygit/themes/$flavour.yml"
theme_link="${XDG_STATE_HOME:-$HOME/.local/state}/lazygit/theme.yml"

mkdir -p "$(dirname "$theme_link")"
ln -sfn "$theme_src" "$theme_link"
