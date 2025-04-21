{ lib, pkgs, config, ... }:
{

  options.tcu_config.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable or disable the tcu config";
  };

  config = lib.mkIf config.tcu_config.enable {
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
      can1 = {
        bitrate = 500000;
      };
    };

    hardware = {
      # deviceTree.overlays = [
      #   {name="ht-mcp-2515-can1-overlay"; dtboFile = ./ht-mcp-2515-can1-overlay.dtbo; }
      #   {name="ht-mcp-2515-can0-overlay"; dtboFile = ./ht-mcp-2515-can0-overlay.dtbo; }
      # ];
      raspberry-pi = {
        config = {
          all = {
            base-dt-params = {
              krnbt = {
                enable = true;
                value = "on";
              };
              spi = {
                enable = true;
                value = "on";
              };
              i2c = {
                enable =true;
                value="off";
              };
            };

            dt-overlays = {
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
                    value = "22"; # this is the individual gpio number for the interrupt of the spi boi
                  };
                };
              };
              mcp2515-can1 = {
                enable = true;
                params = {
                  oscillator =
                    {
                      enable = true;
                      value = "16000000";
                    };
                  interrupt = {
                    enable = true;
                    value = "13"; # this is the individual gpio number for the interrupt of the spi boi
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
