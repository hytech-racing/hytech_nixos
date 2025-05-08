# contains the shared configuration for wifi, ssh and timesync daemon
{ lib, pkgs, config, ... }:
with lib;
let cfg = config.service_names;
in {
  options.service_names = {
    url-name = mkOption {
      type = types.str;
      default = ".car";
    };
    car-ip = mkOption {
      type = types.str;
      default = "192.168.1.30";
    };
    car-wifi-ip = mkOption {
      type = types.str;
      default = "192.168.203.1";
    };
    dhcp-start = mkOption {
      type = types.str;
      default = "192.168.1.70";
    };
    dhcp-end = mkOption {
      type = types.str;
      default = "192.168.1.200";
    };
    default-gateway = mkOption {
      type = types.str;
      default = "192.168.1.1";
    };
    dhcp-interfaces = mkOption {
      type = types.listOf types.str;
      default = [ "enp0s3" "test" ];
    };
  };

  options.standard-services.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable or disable standard services";
  };

  config = lib.mkIf config.standard-services.enable {
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
    networking.nameservers = [ "127.0.0.1" ];
    services.resolved.enable = false;
    services.dnsmasq = {
      enable = true;
      settings = {
        domain-needed = true;
        bogus-priv = true;
        dhcp-authoritative = true;

        # Listen on all interfaces
        interface =
          "lo"; # default loopback to prevent dnsmasq from not starting
        except-interface = "none"; # disables interface filtering

        # Enable DHCP on all interfaces (listen-address 0.0.0.0 does this)
        listen-address = [ "0.0.0.0" ];

        dhcp-range = [
          "interface:eth0,192.168.1.50,192.168.1.150,12h"
          "interface:end0,192.168.1.50,192.168.1.150,12h"
        ];

        dhcp-option = [
          "interface:eth0,option:router,192.168.1.30"
          "interface:eth0,option:netmask,255.255.255.0"
          "interface:end0,option:router,192.168.1.30"
          "interface:end0,option:netmask,255.255.255.0"
        ];

        address = [ "/files.car/192.168.1.30" "/files-wifi.car/192.168.203.1" ];
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts."files.car" = {
        locations."/".proxyPass = "http://127.0.0.1:8001";
      };
      
    };
  };
}

