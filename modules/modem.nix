{ config, lib, pkgs, ... }:
with lib;
let

    cfg = config.services.services.modem;
in {
    config = {
        systemd.services.modem = {
          wantedBy = [ "multi-user.target" ];
          
          };
    };
}