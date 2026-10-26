# STAND-IN, written from the Arch install so the flake evaluates. During
# the NixOS install, replace it with the generated one:
#   nixos-generate-config --root /mnt --show-hardware-config > hardware-configuration.nix
# Formatting the root partition changes its UUID, so this one won't boot as is.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/39e04d8c-a3e1-4074-b9ed-ba05fc3320d7";
    fsType = "ext4";
  };
  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/409C-A9B3";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
