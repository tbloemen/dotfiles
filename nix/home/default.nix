# home-manager only installs packages: the dotfiles are still stowed from
# this repo, so nothing here writes into ~/.config.
{ ... }:

{
  imports = [ ./packages.nix ];

  home.username = "ties";
  home.homeDirectory = "/home/ties";
  # Release the config was first written against; don't bump it on upgrades.
  home.stateVersion = "26.05";
}
