# contains the shared configuration for wifi, ssh and timesync daemon
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.service_names;
in
{
  options.service_names = {
    url-name = mkOption {
      type = types.str;
      default = ".car";
    };
    car-ip = mkOption {
      type = types.str;
      default = "192.168.1.69";
    };
  };
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
      settings.address = "/${cfg.url-name}/${cfg.car-ip}";
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."files${cfg.url-name}" = {
        locations."/".proxyPass = "http://127.0.0.1:8001";
      };
      virtualHosts."rec${cfg.url-name}" = {
        locations."/".proxyPass = "http://127.0.0.1:6969";
      };
    };
  };
}

