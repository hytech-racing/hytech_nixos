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
      after = [ "network.target" ];
      path = [ pkgs.libqmi pkgs.busybox pkgs.sudo ];  # Ensure qmicli and udhcpc are in the PATH

      serviceConfig.ExecStart = ''
        sudo ip link set wwu1i4 down
        echo 'Y' > /sys/class/net/wwu1i4/qmi/raw_ip
        sudo ip link set wwu1i4 up
        sudo qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='fast.t-mobile.com',ip-type=4" --client-no-release-cid
        sudo udhcpc -q -f -i wwu1i4
      '';
    };

    system.activationScripts.setupwwu1i4 = lib.mkAfter '' 
      mkdir -p /etc/network/interfaces.d
      cat << EOF > /etc/network/interfaces.d/wwu1i4
auto wwu1i4
iface wwu1i4 inet manual
     pre-up ip link set wwu1i4 down
     pre-up echo Y > /sys/class/net/wwu1i4/qmi/raw_ip
     pre-up for _ in \$(seq 1 10); do /usr/bin/test -c /dev/cdc-wdm0 && break; /bin/sleep 1; done
     pre-up for _ in \$(seq 1 10); do /usr/bin/qmicli -d /dev/cdc-wdm0 --nas-get-signal-strength && break; /bin/sleep 1; done
     pre-up qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='fast.t-mobile.com',ip-type=4" --client-no-release-cid
     pre-up udhcpc -i wwu1i4
     post-down /usr/bin/qmi-network /dev/cdc-wdm0 stop
EOF
      chmod 644 /etc/network/interfaces.d/wwu1i4
    '';
  };
}

