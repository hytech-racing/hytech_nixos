{ config, lib, pkgs, ... }:
with lib;
let
    
    cfg = config.services.data_acq_frontend;
in {
    config = {
        systemd.services.data_acq_frontend = {
            serviceConfig.path = [ pkgs.nodejs ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.After = [ "data_writer.service" ];
            serviceConfig.requires = [ "data_writer.service" ];

            serviceConfig.ExecStart = "${pkgs.nodejs}/bin/npm start --prefix ${pkgs.frontend_pkg.frontend}";
        };
    };
}
