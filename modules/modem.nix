{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.modem;
  ipCmd = "${pkgs.iproute2}/bin/ip";
in
{
  config = {
    systemd.services.modem = {
      description = "Modem Network Interfaces Setup";
      wantedBy = [ "multi-user.target" ];
      before = [ "network.target" ];
      script = iface: ''
          if ! ip link show wwu1i4 | grep -q "UP"; then
            ${ipCmd} ip link set wwu1i4 down
            echo 'Y' | sudo tee /sys/class/net/wwu1i4/qmi/raw_ip
            ${ipCmd} ip link set wwu1i4 up
            ${ipCmd} qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='fast.t-mobile.com',ip-type=4" --client-no-release-cid
            ${ipCmd} udhcpc -q -f -i wwu1i4
          else
            echo "wwu1i4 is already up."
          fi
        '';
      reload = iface: ''
          ${ipCmd} ip link set wwu1i4 down
        '';
      path = [ pkgs.iproute2 ];
    };
  };
}