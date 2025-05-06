{ lib, config, ... }:
{

  options.hytech-nixos-networking.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable or disable hytech nixos networking";
  };

  config = lib.mkIf config.hytech-nixos-networking.enable {
    networking.useDHCP = true;
    networking.hostName = "hytech-pi";
    networking.firewall.enable = false;
  };

}
