# Base system: nix itself, locale, the user.
{ pkgs, ... }:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [ "@wheel" ];
      # CUDA builds (ollama-cuda, whisper-cpp) aren't on cache.nixos.org.
      extra-substituters = [ "https://nix-community.cachix.org" ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Amsterdam";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_NUMERIC = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_TIME = "nl_NL.UTF-8";
    };
  };
  console.keyMap = "us";
  # Hyprland sets its own layout (modules/input.lua); this is for GDM.
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  users.users.ties = {
    isNormalUser = true;
    description = "Ties Bloemen";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
  };
  programs.zsh.enable = true;

  # Prebuilt binaries that expect /lib64/ld-linux: mason's LSPs, rustup
  # toolchains, uv's pythons and tools, claude's native installer.
  programs.nix-ld.enable = true;

  zramSwap.enable = true;
  services.fstrim.enable = true;

  environment.systemPackages = with pkgs; [
    git
    stow
    vim
    wget
    curl
    pciutils
    usbutils
    lshw
    ntfs3g
    exfatprogs
  ];
}
