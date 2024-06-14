{ config, ... }:
{
  config = {
    networking.useDHCP = true;
    networking.hostName = "hytech-pi";
    # networking.firewall.enable = false;
    networking.firewall = {
      # enable the firewall
      enable = true;

      # always allow traffic from your Tailscale network
      trustedInterfaces = [ "tailscale0" "end0" "can0" "wlan0" "wwu1i4"];

      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port 8765 6969 8001 443 41641];

      # allow you to SSH in over the public internet
      allowedTCPPorts = [ 22 8765 6969 8001 443 41641];

      checkReversePath = "loose";
    };
  };

}
