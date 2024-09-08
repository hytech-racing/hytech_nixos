{ lib, pkgs, config, ... }:
with lib;
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.linux_router;
  
in {
  options.services.linux_router = {
    # Option declarations.
    # Declare what settings a user of this module module can set.
    # Usually this includes a global "enable" option which defaults to false.
    host-ip = mkOption {
      type = types.str;
      default = "192.168.203.1";
    };
    hotspot-name = mkOption {
      type = types.str;
      default = "ht08";
    };
  };
  config = {
    # https://nixos.org/manual/nixos/stable/options.html search for systemd.services.<name>. to get list of all of the options for 
    # new systemd services
    # https://github.com/garywill/linux-router/tree/master?tab=readme-ov-file#cli-usage-and-other-features
    systemd.services.linux_router = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.After = [ "network.target" ];
      serviceConfig.ExecStart =
        "${pkgs.linux-router}/bin/lnxrouter -d -g ${escapeShellArg cfg.host-ip} -n --ap wlan0 ${escapeShellArg cfg.hotspot-name}";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
      serviceConfig.PartOf = "wpa_supplicant-wlan0";
    };
  };
}