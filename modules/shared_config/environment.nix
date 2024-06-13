{ self, config, pkgs, ... }:
{
  config = {
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
      pkgs.tailscale
    ];
  };
}

