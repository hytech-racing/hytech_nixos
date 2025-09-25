{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.logging-service.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable or disable CAN logging service";
  };

  config = lib.mkIf config.logging-service.enable {
    systemd.services.logging-service = {
      description = "CAN Logging Service";
      wantedBy = [ "multi-user.target" ];
      before = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash ${./log.sh}";
        Restart = "on-failure";
        RestartSec = 2;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
