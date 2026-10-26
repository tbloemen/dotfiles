# Everything explicitly installed on Arch that's still in use, minus what
# NixOS modules already provide (Hyprland, pipewire, fonts, docker, ollama:
# see ../modules). Not packaged in nixpkgs, so left out: nordvpn,
# mobilesheets-companion, gazelle-tui, tpack, ttf-aptos, wkhtmltopdf.
{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # --- Desktop: things Hyprland, quickshell and the darkman hooks run ---
    quickshell
    hypridle
    hyprshot
    wlsunset
    darkman
    cliphist
    wl-clipboard
    brightnessctl
    playerctl
    libnotify
    libsecret # secret-tool
    wtype
    glib # gsettings, for darkman's gtk.sh
    xdg-utils
    pavucontrol
    networkmanagerapplet
    wdisplays

    # --- Theme (Catppuccin; gtk.sh / cursor.sh pick the variant) ---
    magnetic-catppuccin-gtk
    (catppuccin-papirus-folders.override {
      flavor = "mocha";
      accent = "mauve";
    })
    catppuccin-cursors.mochaDark
    catppuccin-cursors.mochaLight

    # --- Terminal + shell ---
    ghostty
    kitty
    tmux
    sesh
    zellij
    antidote
    starship
    zoxide
    fzf
    atuin

    # --- CLI tools ---
    neovim
    yazi
    lazygit
    git-lfs
    delta
    difftastic
    gh
    bat
    eza
    fd
    ripgrep
    jq
    yq
    btop
    fastfetch
    duf
    gdu
    tealdeer
    chafa
    pv
    rsync
    rclone
    unzip
    unrar
    _7zz
    file
    lsof
    speedtest-cli
    bitwarden-cli
    pass
    awscli2
    tgpt
    man-pages

    # --- Dev ---
    # rustup, uv and mason keep managing their own toolchains/LSPs, which
    # run through nix-ld. Per-project native deps (notulen's whisper/ALSA)
    # belong in that project's devShell.
    gcc # nvim-treesitter compiles parsers
    gnumake
    pkg-config
    rustup
    python3
    uv
    nodejs
    lua5_1
    luarocks
    jdk21
    tree-sitter
    taplo
    typst
    tinymist
    typstyle
    tectonic
    ast-grep
    perf
    docker-compose
    supabase-cli
    posting
    atac
    bruno
    dbeaver-bin
    renderdoc
    podman-desktop
    jetbrains-toolbox
    gitkraken
    opencode
    codex
    github-copilot-cli

    # --- AI / meetings (notulen) ---
    (whisper-cpp.override { cudaSupport = true; })

    # --- Apps ---
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    firefox
    google-chrome
    thunderbird
    obsidian
    discord
    signal-desktop
    slack
    zoom-us
    bitwarden-desktop
    high-tide
    eduvpn-client
    zotero
    libreoffice-still
    gnucash
    beancount
    fava
    obs-studio
    audacity
    inkscape
    musescore
    openshot-qt
    mpv
    loupe
    evince
    nautilus
    file-roller
    baobab
    gnome-calculator
    gnome-disk-utility
    meld
    authenticator

    # --- Fun ---
    cbonsai
    cmatrix
    pipes
    kdePackages.kpat
  ];
}
