{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking.modem;
  ipCmd = "${pkgs.iproute2}/bin/ip";
  qmiCmd = "${pkgs.libqmi}/bin/qmicli";
  udhcpcCmd = "${pkgs.busybox}/bin/udhcpc";
in
{
  options.networking.modem = {
    enable = mkEnableOption "Modem network interfaces";

    interfaces = mkOption {
      default = { };
      example = literalExpression ''{
        wwu1i4 = {
          apn = "fast.t-mobile.com";
        };
      }'';
      type = types.attrsOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "The name of the modem interface.";
          };
          apn = mkOption {
            type = types.str;
            description = "The APN of the modem interface.";
          };
        };
      });
      description = "Modem interface configurations.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      iproute2
      libqmi
      busybox
    ];

    systemd.services.modem-setup = {
      description = "Modem Network Interfaces Setup";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.iproute2 pkgs.libqmi pkgs.busybox ];

      serviceConfig = {
        ExecStart = concatStringsSep "\n" (mapAttrsToList
          (name: iface: ''
            ${ipCmd} link set ${name} down
            echo 'Y' > /sys/class/net/${name}/qmi/raw_ip
            ${ipCmd} link set ${name} up
            ${qmiCmd} -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='${iface.apn}',ip-type=4" --client-no-release-cid
            ${udhcpcCmd} -q -f -i ${name}
          '')
          cfg.interfaces);
        Restart = "always";
      };
    };

    system.activationScripts.setupModemInterfaces = lib.mkAfter '' 
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

