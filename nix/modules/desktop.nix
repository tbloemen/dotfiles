# Hyprland session and everything the dotfiles expect around it.
{ pkgs, ... }:

{
  services.displayManager.gdm.enable = true;

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true; # PAM service for the hypridle fallback
  # Electron/Chromium apps (Discord, Obsidian, Slack, ...) on Wayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # The gtk portal reports gsettings' color-scheme, which is how ghostty,
  # Zen, tmux and Thunderbird follow darkman (see CLAUDE.md).
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  programs.dconf.enable = true;

  security.polkit.enable = true; # the agent is quickshell
  services.gnome.gnome-keyring.enable = true; # secret-tool (Todoist token)

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true; # blueman-applet is the BlueZ agent

  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openconnect
      networkmanager-openvpn
    ];
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    material-symbols
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    dejavu_fonts
    liberation_ttf
    open-sans
  ];
}
