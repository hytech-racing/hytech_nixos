{ lib, pkgs, config, ... }:
with lib;
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.param_webserver;

in
{
  options.services.param_webserver = {
    # Option declarations.
    # Declare what settings a user of this module module can set.
    # Usually this includes a global "enable" option which defaults to false.
    enable = mkOption {
      default = false;
      type = with types; bool;
      description = ''
        param webserver service
      '';
    };
    # what the mcu is sending to
    host-recv-ip = mkOption {
      type = types.str;
      default = "192.168.1.69";
    };

    # what the params webserver is sending to
    web-port = mkOption {
      type = types.int;
      default = 8002;
    };
    mcu-ip = mkOption {
      type = types.str;
      default = "192.168.1.30";
    };
    param-recv-port = mkOption {
      type = types.int;
      default = 20001;
    };
    param-send-port = mkOption {
      type = types.int;
      default = 20000;
    };
  };
  config = lib.mkIf cfg.enable {
    # https://nixos.org/manual/nixos/stable/options.html search for systemd.services.<name>. to get list of all of the options for 
    # new systemd services
    systemd.services.param_webserver = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.After = [ "network.target" ];
      serviceConfig.ExecStart =
        "${pkgs.params_interface}/bin/params_interface.py ${escapeShellArg cfg.param-send-port} ${escapeShellArg cfg.param-recv-port} ${escapeShellArg cfg.web-port} ${escapeShellArg cfg.host-recv-ip} ${escapeShellArg cfg.mcu-ip}";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}
