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
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash ${./log.sh}";
        Restart = "on-failure";
        RestartSec = 2;
        User = "root";
        WorkingDirectory = "/mnt";
        StandardOutput = "journal";
        StandardError = "journal";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_RAW";
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_RAW";
        NoNewPrivileges = false;
        RequiresMountsFor = [ "/mnt" ];
        Environment = "PATH=${
          lib.makeBinPath [
            pkgs.bash
            pkgs.can-utils
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.iproute2
          ]
        }";
      };

    };
  };
}
