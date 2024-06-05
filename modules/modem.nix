{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.modem;
in
{
  config = {
    systemd.services.modem = {
      description = "Modem Network Interfaces Setup";
      wantedBy = [ "multi-user.target" ];
      before = [ "network.target" ];
      script = ''
            sudo ip link set wwu1i4 down
            echo 'Y' | sudo tee /sys/class/net/wwu1i4/qmi/raw_ip
            sudo ip link set wwu1i4 up
            sudo qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='fast.t-mobile.com',ip-type=4" --client-no-release-cid
            sudo udhcpc -q -f -i wwu1i4
        '';
      reload = ''
          sudo ip link set wwu1i4 down
        '';
    };
  };
}