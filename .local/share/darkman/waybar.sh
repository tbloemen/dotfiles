#!/bin/sh
# darkman hook: refresh waybar's custom/darkman indicator after the mode
# changes via any trigger — not just the waybar toggle button itself (e.g.
# `darkman set`, sunrise/sunset). The module re-queries `darkman get` itself
# on the signal, so the mode ("dark"/"light") passed in $1 is only used here
# to validate the call.

case "$1" in
dark | light)
	pkill -RTMIN+8 waybar
	;;
*)
	echo "usage: $0 {dark|light}" >&2
	exit 1
	;;
esac
