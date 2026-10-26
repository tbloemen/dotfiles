# Background services that were enabled on Arch.
{ pkgs, ... }:

{
  virtualisation.docker.enable = true;

  # Notulen summarizes with a local model.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # Opens its port (53317) in the firewall.
  programs.localsend.enable = true;

  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };
}
