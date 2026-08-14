#!/usr/bin/env bash
# Rofi power menu, opened by the waybar custom/power module.
#
# Adapted from sameemul-haque/dotfiles (originally adi1090x/rofi type-2
# style-5): the theme is re-pointed at this repo's shared rofi palette so it
# follows darkman, and the actions are Hyprland/systemd instead of the
# upstream multi-WM/mpd/alsa dance.
#
# Selections are matched on rofi's row *index* (-format i), never on the icon
# text. Upstream compared the chosen string against the glyph variables, which
# fails open in the worst possible way: if a glyph is empty or gets mangled,
# an empty selection (Escape, or a killed rofi) compares equal to it and fires
# whatever action that variable guards. Indexes cannot go blank, and rofi's
# exit status distinguishes "cancelled" from "chose row 0".

theme="$HOME/.config/rofi/powermenu/style.rasi"

# Material Design Icons from the Nerd Font (same range waybar's icons use).
lock='󰌾'
suspend='󰒲'
logout='󰍃'
reboot='󰜉'
shutdown='󰐥'

cancel='󰅖'
accept='󰄬'

menu() {
	printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" |
		rofi -dmenu -format i -theme "$theme"
}

# Same theme, re-shaped into a centered two-button dialog. Cancel is row 0 so
# that the default selection — what Enter picks — is the harmless one.
confirmed() {
	local choice
	choice=$(
		printf '%s\n' "$cancel" "$accept" |
			rofi -dmenu -format i \
				-mesg "$1" \
				-theme-str 'window {location: center; anchor: center; width: 350px; x-offset: 0px; y-offset: 0px;}' \
				-theme-str 'mainbox {children: [ "message", "listview" ];}' \
				-theme-str 'listview {columns: 2; lines: 1;}' \
				-theme-str 'element {padding: 12px 0px;}' \
				-theme "$theme"
	) || return 1 # Escape / killed rofi: non-zero exit, no action.
	[ "$choice" = "1" ]
}

selected=$(menu) || exit 0 # cancelled

case "$selected" in
0)
	# Via logind rather than hyprlock directly, so it takes the same path as
	# hypridle's idle timeout (its lock_cmd guards against a second instance).
	loginctl lock-session
	;;
1)
	# hypridle's before_sleep_cmd locks the session on the way down.
	confirmed 'Suspend?' && systemctl suspend
	;;
2)
	# The wiki recommends hyprshutdown over the exit dispatcher (it brings the
	# session down in order instead of yanking the compositor out from under
	# its clients); same preference-with-fallback as the SUPER+M bind in
	# hyprland.lua. The fallback has to be the `hl.dsp.exit()` Lua call, not the
	# old bare `exit` keyword: hyprctl dispatch parses its argument as Lua on
	# this version, so `exit` reads as an undefined global and fails silently
	# behind waybar's `&`.
	confirmed 'Log out?' &&
		{ command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown ||
			hyprctl dispatch 'hl.dsp.exit()'; }
	;;
3)
	confirmed 'Reboot?' && systemctl reboot
	;;
4)
	confirmed 'Shut down?' && systemctl poweroff
	;;
esac
