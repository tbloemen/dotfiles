#!/bin/sh
# darkman hook: switch the tmux catppuccin flavour live (latte/mocha).
# darkman passes the current mode ("dark"/"light") as $1.

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

# Nothing to do if no tmux server is running.
tmux list-sessions >/dev/null 2>&1 || exit 0

tmux set-option -g @catppuccin_flavour "$flavour"

# Re-run the catppuccin plugin so the status line is regenerated with the
# new flavour, then push the update to every attached client.
for plugin in \
	"$HOME/.config/tmux/plugins/catppuccin-tmux/catppuccin.tmux" \
	"$HOME/.tmux/plugins/catppuccin-tmux/catppuccin.tmux"; do
	if [ -x "$plugin" ]; then
		tmux run-shell "$plugin"
		break
	fi
done

tmux refresh-client -S
