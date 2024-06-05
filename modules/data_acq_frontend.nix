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
            activationScripts =
            ''
                sudo ip link set wwu1i4 down
                echo 'Y' | sudo tee /sys/class/net/wwu1i4/qmi/raw_ip
                sudo ip link set wwu1i4 up
                sudo qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='fast.t-mobile.com',ip-type=4" --client-no-release-cid
                sudo udhcpc -q -f -i wwu1i4
            '';
            serviceConfig.After = [ "network.target" ];
            serviceConfig.ExecStart = "${pkgs.nodePackages.serve}/bin/serve ${pkgs.frontend_pkg.frontend}/build -l 4000";
        };
    };
}
