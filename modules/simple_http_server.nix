{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.http_server;
in
{
  options.services.http_server = {
    port = mkOption {
      type = types.int;
      default = 8001;
    };
  };
  config = {
    systemd.services.http_server = {
      wantedBy = [ "multi-user.target" ];
      description = "Allows you to access your MCAP files";
      activationScripts =
            ''
                sudo ip link set wwu1i4 down
                echo 'Y' | sudo tee /sys/class/net/wwu1i4/qmi/raw_ip
                sudo ip link set wwu1i4 up
                sudo qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='fast.t-mobile.com',ip-type=4" --client-no-release-cid
                sudo udhcpc -q -f -i wwu1i4
            '';
      serviceConfig.ExecStart = "${pkgs.simple-http-server}/bin/simple-http-server --port ${escapeShellArg cfg.port} /home/nixos/recordings";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}
