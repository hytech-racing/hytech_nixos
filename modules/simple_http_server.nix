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
  config = {
    systemd.services.http_server = {
      wantedBy = [ "multi-user.target" ];
      description = "Allows you to access your MCAP files";
      serviceConfig.ExecStart = "${pkgs.simple-http-server}/bin/simple-http-server --port ${escapeShellArg cfg.port} /home/nixos/recordings";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}
