{ config, lib, pkgs, ... }:
with lib;
let
    
    cfg = config.services.data_acq_frontend;
in {
    config = {
        systemd.services.data_acq_frontend = {
            serviceConfig.path = [ pkgs.nodejs ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.After = [ "network.target" ];
            serviceConfig.requires = [ "data_writer.service" ];
            
            serviceConfig.ExecStart = "npm start --prefix ${pkgs.frontend_pkg.frontend}";
        };
    };
}
