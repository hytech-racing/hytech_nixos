{ config, lib, pkgs, ... }: 
let
  jsonContent = builtins.readFile ./config/drivebrain_config.json;
in
{
  options.drivebrain-service.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable or disable the drivebrain service";
  };

  config = lib.mkIf config.drivebrain-service.enable {

    systemd.services.drivebrain-service = {
      description = "Drivebrain Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        After = [ "network.target" ];
        ExecStart = "${pkgs.drivebrain_software}/bin/alpha_build -p /home/nixos/config/drivebrain_config.json -d ${pkgs.ht_can_pkg}/hytech.dbc";
        ExecStop = "/bin/kill -9 $MAINPID";
        Restart = "on-failure";
      };
    };

    systemd.services.debug-drivebrain-service = {
      description = "Debug Drivebrain Service";
      wantedBy = []; # not wanted by anything so does not start automatically
      # after = [ "network.target" ];

      serviceConfig = {
        After = [ "network.target" ];
        ExecStart = "/home/nixos/launch.sh";
        ExecStop = "/bin/kill -9 $MAINPID";
        Restart = "on-failure";
      };
    };

    # Create /home/nixos/config directory if it doesn't exist
    system.activationScripts.createConfigDir = pkgs.lib.mkForce ''
      mkdir -p /home/nixos/config
      chown nixos:users /home/nixos/config
    '';

    # Write JSON content from repo to /home/nixos/config/drivebrain_config.json file if it doesn't exist
    system.activationScripts.writeConfigFile = pkgs.lib.mkForce ''
      if [ ! -f "/home/nixos/config/drivebrain_config.json" ]; then
        echo "${jsonContent}" > "/home/nixos/config/drivebrain_config.json"
        chown nixos:users /home/nixos/config/drivebrain_config.json
      fi
    '';

    system.activationScripts.writeDebugDBLaunchScript = pkgs.lib.mkForce ''
      if [ ! -f "/home/nixos/launch.sh" ]; then
        echo "#!/run/current-system/sw/bin/bash" > "/home/nixos/launch.sh\n"
        echo "${pkgs.drivebrain_software}/bin/alpha_build -p /home/nixos/config/drivebrain_config.json -d ${pkgs.ht_can_pkg}/hytech.dbc" > "/home/nixos/launch.sh"
        chown nixos:users /home/nixos/launch.sh
        chmod +x /home/nixos/launch.sh
      fi
    '';
    
  };
}