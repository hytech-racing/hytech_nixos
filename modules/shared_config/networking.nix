{ config, ... }:
{
  config = {
    networking.useDHCP = true;
    networking.hostName = "hytech-pi";
    networking.firewall.enable = false;
  };

}
