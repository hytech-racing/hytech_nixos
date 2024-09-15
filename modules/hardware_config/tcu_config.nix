{ lib, pkgs, config, ... }:
{
  config = {
    networking.wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
    networking.extraHosts =
      ''
        192.168.203.1 hytech-pi
      '';
    systemd.services.wpa_supplicant.wantedBy = lib.mkOverride 10 [ "default.target" ];
    networking.interfaces.end0.ipv4 = {
      addresses = [
        {
          address = "192.168.1.69"; # Your static IP address
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
    networking.can.enable = true;
    networking.can.interfaces = {
      can0 = {
        bitrate = 500000;
      };
    };
    hardware = {
      bluetooth.enable = true;
      raspberry-pi = {
        config = {
          all = {
            base-dt-params = {
              #           # enable autoprobing of bluetooth driver
              #           # https://github.com/raspberrypi/linux/blob/c8c99191e1419062ac8b668956d19e788865912a/arch/arm/boot/dts/overlays/README#L222-L224
              krnbt = {
                enable = true;
                value = "on";
              };
              spi = {
                enable = true;
                value = "on";
              };
            };
            dt-overlays = {
              spi-bcm2835 = {
                enable = true;
                params = { };
              };
              mcp2515-can0 = {
                enable = true;
                params = {
                  oscillator =
                    {
                      enable = true;
                      value = "16000000";
                    };
                  interrupt = {
                    enable = true;
                    value = "16"; # this is the individual gpio number for the interrupt of the spi boi
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
