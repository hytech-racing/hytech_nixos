{ lib, config, ... }: {

  options.basic-vm-hw.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable or disable basic vm hardware";
  };


  # System configuration
  config = lib.mkIf config.basic-vm-hw.enable {
    boot.loader.grub = {
      enable = true;
      device = "/dev/sda"; # Use the specific device path for GRUB installation
      efiSupport = false; # Set to true if using UEFI
    };
    
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    # swapDevices = [
    #   # Optional: If you use swap
    #   { device = "/dev/disk/by-label/swap"; }
    # ];
  };
}
