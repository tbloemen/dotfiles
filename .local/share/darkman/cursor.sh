#!/bin/sh
# darkman hook: swap the Catppuccin cursor between the dark and light variant.
# hyprland.lua seeds XCURSOR_THEME/HYPRCURSOR_THEME from darkman's mode.txt at
# launch; this changes it live. darkman passes the mode ("dark"/"light") as $1.

case "$1" in
dark | light) theme="catppuccin-mocha-$1-cursors" ;;
*)
	echo "usage: $0 {dark|light}" >&2
	exit 1
	;;
esac
size=24

# Hyprland's own cursor (and the one it hands to Wayland clients).
hyprctl setcursor "$theme" "$size" >/dev/null

# GTK apps read the cursor from gsettings / settings.ini, not from Hyprland.
gsettings set org.gnome.desktop.interface cursor-theme "$theme"
gsettings set org.gnome.desktop.interface cursor-size "$size"

for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
	[ -f "$ini" ] && sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$theme/" "$ini"
done
