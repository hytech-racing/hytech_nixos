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
    services.tailscale = {
        enable = true;
        useRoutingFeatures = if cfg.advertiseExitNode then "server" else "client";
      };
    # create a oneshot job to authenticate to Tailscale
    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 2

        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi

        # otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up -authkey tskey-auth-kqqyjczLDn11CNTRL-NJTf5yYxuJ29t81MoWyqJ2QbY8gaQrs52
      '';

      # services.dnsmasq = {
      #   enable = true;
      #   settings = {
      #     address = "/${cfg.url-name}/${cfg.car-ip}/";
      #     domain-needed = true;
      #     interface = cfg.dhcp-interfaces;
      #     dhcp-authoritative = true;
      #     dhcp-range = [ "eth,${cfg.dhcp-start},${cfg.dhcp-end},12h"];
      #     dhcp-option = [ "option:router,${cfg.default-gateway}" "option:netmask,255.255.255.0" ];
      #   };
      # };

      # services.nginx = {
      #   enable = true;
      #   recommendedProxySettings = true;
      #   recommendedTlsSettings = true;
      #   virtualHosts."files${cfg.url-name}" = {
      #     locations."/".proxyPass = "http://127.0.0.1:8001";
      #   };
      #   virtualHosts."rec${cfg.url-name}" = {
      #     locations."/".proxyPass = "http://127.0.0.1:6969";
      #   };
      #   virtualHosts."params${cfg.url-name}" = {
      #     locations."/".proxyPass = "http://127.0.0.1:8000";
      #   };
      #   # virtualHosts."foxglove${cfg.url-name}" = {
      #   #   locations."/".proxyPass = "http://127.0.0.1:8765";
      #   #   locations."/".proxyWebsockets = true;
      #   # };
      # };
    };
  };
}

