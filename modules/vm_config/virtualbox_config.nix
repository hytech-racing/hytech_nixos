{ config, ... }:
{
  config = {
    virtualisation.virtualbox.guest.enable = true;
    boot.kernelModules = [ "vboxguest" "vboxsf" ];
    services.getty.autologinUser = "root";
    users.users.root.password = "root";
    networking.interfaces.enp0s3.ipv4 = {
      addresses = [
        {
          address = "192.168.86.35"; # Your static IP address
          prefixLength = 24; # Netmask, 24 for 255.255.255.0
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "192.168.1.1"; # Your gateway IP address
        }
      ];
    };
  };

}
