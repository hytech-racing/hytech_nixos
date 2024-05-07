{ lib, pkgs, config, ... }:
with lib;
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.param_webserver;
  
in {
  options.services.param_webserver = {
    # Option declarations.
    # Declare what settings a user of this module module can set.
    # Usually this includes a global "enable" option which defaults to false.
    
    
    # what the mcu is sending to
    host-recv-ip = mkOption {
      type = types.str;
      default = "192.168.1.69";
    };

    # what the params webserver is sending to
    mcu-ip = mkOption {
      type = types.str;
      default = "192.168.1.12";
    };
    param-recv-port = mkOption {
      type = types.int;
      default = 2002;
    };
    param-send-port = mkOption {
      type = types.int;
      default = 2001;
    };
  };
  config = {
    # https://nixos.org/manual/nixos/stable/options.html search for systemd.services.<name>. to get list of all of the options for 
    # new systemd services
    systemd.services.param_webserver = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.After = [ "network.target" ];
      serviceConfig.ExecStart =
        "${pkgs.params_interface}/bin/params_interface.py --host_ip ${escapeShellArg cfg.host-recv-ip} --ip ${escapeShellArg cfg.mcu-ip} --send_port ${escapeShellArg cfg.param-send-port} --recv_port ${escapeShellArg cfg.param-recv-port}";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}