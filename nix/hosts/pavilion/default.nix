# HP Pavilion Gaming 15-ec2xxx: Ryzen 7 5800H (Radeon iGPU drives eDP-1) +
# RTX 3050 Mobile (drives HDMI-A-1), dual boot with Windows.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system.nix
    ../../modules/desktop.nix
    ../../modules/services.nix
  ];

  networking.hostName = "pavilion";

  # GRUB like on Arch, so os-prober keeps finding Windows. The ESP stays at
  # /boot/efi (260M is too small to hold NixOS generations, which GRUB keeps
  # on the root partition instead).
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      configurationLimit = 10;
    };
  };
  # Windows keeps the hardware clock in local time.
  time.hardwareClockInLocalTime = true;

  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # nvidia-open on Arch. PRIME offload: the iGPU renders by default and the
  # dGPU powers down when idle; `nvidia-offload <app>` runs an app on it.
  # HDMI is wired to the dGPU, so an external monitor keeps it awake.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    nvidiaSettings = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Release the system was first installed with; don't bump it on upgrades.
  system.stateVersion = "26.05";
}
