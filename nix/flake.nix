{
  description = "NixOS + home-manager for ties (target of the move off Arch)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Not in nixpkgs (zen-browser-bin from the AUR on Arch).
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    {
      nixosConfigurations.pavilion = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/pavilion
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              # Packages land in /etc/profiles/per-user/ties.
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.ties = import ./home;
            };
          }
        ];
      };
    };
}
