{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.grpcui;
in
{
  options.services.grpcui = {
    enable = mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable or disable the http server";
    };
    host-port = mkOption {
      type = types.int;
      default = 10922;
    };
    service-port = mkOption {
      type = types.int;
      default = 6969;
    };
  };

  config = mkIf config.services.grpcui.enable {
    systemd.services.grpcui = {
      wantedBy = [ "multi-user.target" ];
      description = "simple grpcui service for the car";
      serviceConfig.ExecStart = "${pkgs.grpcui}/bin/grpcui -plaintext -port ${escapeShellArg cfg.host-port} -bind 0.0.0.0 localhost:${escapeShellArg cfg.service-port}";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}
