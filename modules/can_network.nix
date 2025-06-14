{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking.can;
  ipCmd = "${pkgs.iproute2}/bin/ip";
in
{
  options.networking.can = {
    enable = mkEnableOption "CAN network interfaces";

    interfaces = mkOption {
      default = { };
      example = literalExpression ''{
        can0 = {
          bitrate = 500000;
        };
      }'';
      type = types.attrsOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "The name of the CAN interface.";
          };
          enable = mkOption {
            type = types.boolean;
            description = "enable CAN interface";
            default = true;
          };
          bitrate = mkOption {
            type = types.int;
            default = 500000;
            description = "The bitrate of the CAN interface.";
          };
        };
      });
      description = "CAN interface configurations.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.can-setup = {
      description = "CAN Network Interfaces Setup";
      wantedBy = [ "multi-user.target" ];
      before = [ "network.target" ];
      script = concatStringsSep "\n" (mapAttrsToList
        (name: iface: ''
          if ! ip link show ${name} | grep -q "UP"; then
            if [[ "${name}" =~ ^vcan[0-9]+$ ]]; then
              echo "bringing up virtual CAN (vcan)"
              ${ipCmd} link add dev ${name} type vcan
            else
              echo "bringing up physical CAN (can)"
              ${ipCmd} link set ${name} txqueuelen 1000
              ${ipCmd} link set ${name} type can bitrate ${toString iface.bitrate}
            fi
            ${ipCmd} link set up ${name}
          else
            echo "CAN interface ${name} is already up."
          fi
        '')
        cfg.interfaces);

      reload = concatStringsSep "\n" (mapAttrsToList
        (name: iface: ''
          ${ipCmd} link set down ${name}
        '')
        cfg.interfaces);
      path = [ pkgs.iproute2 ];
    };
  };
}
