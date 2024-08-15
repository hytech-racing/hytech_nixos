{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.modem;

in
{
  config = {

    systemd.services.modem = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        After = [ "network.target" "ttyUSB2.device" "cdc-wdm0" ];
        ExecStart = ./modem-setup.sh;
      };
    };
  };
}
