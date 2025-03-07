{ self, lib, config, pkgs, ... }:
{

  options.hytech-nixos-environment.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable or disable the hytech nixos environment";
  };

  config = lib.mkIf config.hytech-nixos-environment.enable {

    environment.etc."hytech_nixos".source = self;
    environment.systemPackages = [
      pkgs.can-utils
      pkgs.ethtool
      pkgs.python3
      pkgs.nodePackages.serve
      pkgs.getconf
      pkgs.python311Packages.cantools
      pkgs.ht_can_pkg
      pkgs.htop
      pkgs.simple-http-server
      pkgs.v4l-utils
      pkgs.fswebcam
      pkgs.tmux
      pkgs.ser2net
      pkgs.i2c-tools
      (pkgs.python3.withPackages (ps: with ps; [ numpy pandas smbus2 i2c-tools ]))
    ];
  };
}

