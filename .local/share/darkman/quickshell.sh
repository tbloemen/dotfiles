#!/bin/sh
# darkman hook: push the new mode straight into the quickshell bar's Colors
# singleton via its IpcHandler, instead of the waybar.sh dance this replaces
# (colors.css file swap + SIGRTMIN+8 signal with a /proc SigCgt-mask race
# check). qs ipc either reaches the running "bar" instance or fails loudly --
# there's no signal-delivered-before-handler-installed race to defend against.
# darkman passes the current mode ("dark"/"light") as $1.

case "$1" in
dark | light) mode="$1" ;;
*)
	echo "usage: $0 {dark|light}" >&2
	exit 1
	;;
esac

qs -c bar ipc call darkman setMode "$mode"
