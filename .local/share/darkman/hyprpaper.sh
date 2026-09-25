#!/bin/sh
# darkman hook: switch the desktop wallpaper between the light and dark frame
# of whichever dynamic wallpaper ~/wallpapers/active points at.
# darkman passes the current mode ("dark"/"light") as $1.
#
# ~/wallpapers/active is a symlink to a wallpapers/<name>/ directory holding
# light.png + dark.png -- repoint it (e.g. `ln -sfn other-wallpaper active` in
# wallpapers/) to switch which dynamic wallpaper darkman drives, with no edits
# here or in hyprland.lua.
#
# hyprpaper.conf points both monitors at a stable symlink
# (~/.cache/hyprpaper/current.png) instead of a wallpaper file directly, so it
# never needs editing again -- this hook just swaps the symlink target, the
# same trick lazygit.sh uses for its theme file. The live hyprctl hyprpaper
# "wallpaper" IPC request (the only one hyprpaper's 0.8.x protocol supports)
# rejects a leading `~`, unlike hyprpaper.conf's own parser, so $HOME is
# expanded explicitly below.

case "$1" in
dark | light) ;;
*)
	echo "usage: $0 {dark|light}" >&2
	exit 1
	;;
esac

link="$HOME/.cache/hyprpaper/current.png"
mkdir -p "$(dirname "$link")"
ln -sfn "$HOME/wallpapers/active/$1.png" "$link"

# Best-effort: darkman run also fires this at startup, seeded before hyprpaper
# launches (see hyprland.lua's hyprland.start block) -- hyprpaper reads this
# symlink itself at startup, so these IPC calls only matter for a live switch.
hyprctl hyprpaper wallpaper "eDP-1,$link" >/dev/null 2>&1
hyprctl hyprpaper wallpaper "HDMI-A-1,$link" >/dev/null 2>&1
