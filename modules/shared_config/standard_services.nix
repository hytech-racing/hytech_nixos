# contains the shared configuration for wifi, ssh and timesync daemon
{ lib, pkgs, config, ... }:
{
  config = {
    systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];
    services.openssh = { enable = true; };
    services.openssh.listenAddresses = [
      {
        addr = "0.0.0.0";
        port = 22;
      }
      {
        addr = ":";
        port = 22;
      }
    ];

    services.dnsmasq = {
      enable = true;
      settings.address = "/hytech.yeet/192.168.86.35";
      
    };
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."hytech.yeet" = {
        locations."/files".proxyPass = "http://192.168.86.35:8001";
      };
    };

  };
}

