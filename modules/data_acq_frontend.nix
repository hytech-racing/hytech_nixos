{ config, lib, pkgs, ... }:
with lib;
let

    cfg = config.services.user.services.data_acq_frontend;
in {
    config = {
        systemd.user.services.data_acq_frontend = {
            path = [ pkgs.nodejs pkgs.bash pkgs.nodePackages.serve pkgs.getconf ];
            enable = true;
            wantedBy = [ "default.target" ];
            serviceConfig.After = [ "network.target" ];
            serviceConfig.ExecStart = "${pkgs.nodePackages.serve}/bin/serve ${pkgs.frontend_pkg.frontend}/build -l 4000";
        };
    };
}
