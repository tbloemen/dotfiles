#!/bin/sh
# darkman hook: switch dunst between the Catppuccin Latte (light) and Mocha
# (dark) palettes.
# darkman passes the current mode ("dark"/"light") as $1.
#
# dunst has no include directive, so the colors are swapped through a drop-in
# in dunstrc.d/ (dunst >= 1.7 reads dunstrc.d/*.conf after dunstrc, last wins).
# The 99- prefix keeps the fragment sorting last so it overrides dunstrc, which
# keeps the Mocha values as a fallback for when no drop-in exists yet.

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

dropin_dir="$HOME/.config/dunst/dunstrc.d"
mkdir -p "$dropin_dir"
cp "$HOME/.config/dunst/colors-$flavour.conf" "$dropin_dir/99-colors.conf"

# Best-effort: `darkman run` also fires this at startup, possibly before dunst
# is up. The drop-in is already on disk by then, so dunst picks it up when it
# starts and the failed reload costs nothing.
dunstctl reload 2>/dev/null
