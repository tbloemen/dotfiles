#!/bin/sh
# darkman hook: switch rofi between the Catppuccin Latte (light) and Mocha
# (dark) palettes.
# darkman passes the current mode ("dark"/"light") as $1.
#
# Every theme in ~/.config/rofi @imports palette.rasi, which imports the
# colors.rasi written here, so one copy re-themes the launcher, the wifi
# menus and anything else driven by those themes.
#
# No reload signal exists or is needed: rofi is not a daemon — each menu is a
# fresh process that reads its theme at launch, so the next invocation picks
# up the new palette.

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

cp "$HOME/.config/rofi/colors-$flavour.rasi" "$HOME/.config/rofi/colors.rasi"
