#!/bin/sh
# darkman hook: switch GTK (and, via the freedesktop color-scheme portal,
# ghostty + Zen) between Catppuccin Latte (light) and Mocha (dark).
# darkman passes the current mode ("dark"/"light") as $1.

case "$1" in
dark)
	scheme="prefer-dark"
	gtk_theme="Catppuccin-Purple-Dark"
	icon_theme="Qogir-Dark"
	prefer_dark=1
	;;
light)
	scheme="prefer-light"
	gtk_theme="Catppuccin-Purple-Light"
	icon_theme="Qogir-Light"
	prefer_dark=0
	;;
*)
	echo "usage: $0 {dark|light}" >&2
	exit 1
	;;
esac

theme_dir="$HOME/.themes/$gtk_theme"

# 1. gsettings — read by the gtk xdg-desktop-portal, so ghostty and Zen
#    (and any libadwaita app) follow the color-scheme automatically.
gsettings set org.gnome.desktop.interface color-scheme "$scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"

# 2. GTK4 / libadwaita read CSS from ~/.config/gtk-4.0 — point it at the
#    chosen theme's stylesheets.
if [ -d "$theme_dir/gtk-4.0" ]; then
	ln -sfn "$theme_dir/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
	ln -sfn "$theme_dir/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
	ln -sfn "$theme_dir/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets"
fi

# 3. settings.ini for GTK3 apps that don't honour gsettings directly.
gtk3_ini="$HOME/.config/gtk-3.0/settings.ini"
if [ -f "$gtk3_ini" ]; then
	sed -i \
		-e "s/^gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" \
		-e "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" \
		-e "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$prefer_dark/" \
		"$gtk3_ini"
fi

gtk4_ini="$HOME/.config/gtk-4.0/settings.ini"
if [ -f "$gtk4_ini" ]; then
	sed -i \
		-e "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$prefer_dark/" \
		"$gtk4_ini"
fi
