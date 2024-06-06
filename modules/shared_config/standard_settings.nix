# contains the shared configuration for nix, the nixos user on tcu, standard programs
{ config, lib, ... }:
{
  config = {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.require-sigs = false;
    users.users.nixos.group = "nixos";
    users.users.root.initialPassword = "root";
    users.users.nixos.password = "nixos";
    users.groups.nixos = { };
    users.users.nixos.extraGroups = [ "wheel" ];

    users.users.nixos.isNormalUser = true;
    system.stateVersion = "23.11";
    system.activationScripts.createRecordingsDir = lib.stringAfter [ "users" ] ''
      mkdir -p /home/nixos/recordings
      chown nixos:users /home/nixos/recordings
    '';
    system.activationScripts.setupWwu1i4 = lib.mkAfter '' 
          cat << EOF | sudo tee /etc/network/interfaces.d/wwu1i4 > /dev/null
          iface wwu1i4 inet manual
               pre-up ifconfig wwu1i4 down
               pre-up echo Y > /sys/class/net/wwu1i4/qmi/raw_ip
               pre-up for _ in \$(seq 1 10); do /usr/bin/test -c /dev/cdc-wdm0 && break; /bin/sleep 1; done
               pre-up for _ in \$(seq 1 10); do /usr/bin/qmicli -d /dev/cdc-wdm0 --nas-get-signal-strength && break; /bin/sleep 1; done
               pre-up sudo qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='fast.t-mobile.com',ip-type=4" --client-no-release-cid
               pre-up udhcpc -i wwu1i4
               post-down /usr/bin/qmi-network /dev/cdc-wdm0 stop
          EOF
          sudo chmod 644 /etc/network/interfaces.d/wwu1i4
        '';
    users.extraUsers.nixos.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSt9Z8Qdq068xj/ILVAMqmkVyUvKCSTsdaoehEZWRut rcmast3r1@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhMu3LzyGPjh0WkqV7kZYwA+Hyd2Bfc+1XQJ88HeU4A rcmast3r1@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZRFnx0tlpUAFqnEqP2R/1y8oIAPXhL2vW/UU727vw8 eddsa-key-Pranav"
    ];
  programs.git = {
    enable = true;
    config = {
      user.name = "Ben Hall";
      user.email = "rcmast3r1@gmail.com";
    };
  };
  };
}
