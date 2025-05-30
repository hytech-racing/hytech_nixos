{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.http_server;
in
{
  options.services.http_server = {
    port = mkOption {
      type = types.int;
      default = 8001;
    };
  };

  options.simple_http_server.enable = mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable or disable the http server";
  };

  config = mkIf config.simple_http_server.enable {
    systemd.services.http_server = {
      wantedBy = [ "multi-user.target" ];
      description = "Allows you to access your MCAP files";
      serviceConfig.ExecStart = "${pkgs.simple-http-server}/bin/simple-http-server --port ${escapeShellArg cfg.port} /home/nixos/";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}
