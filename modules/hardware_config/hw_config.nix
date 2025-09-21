{ lib, pkgs, config, ... }:
let
  ipCmd = "${pkgs.iproute2}/bin/ip";
in
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
    # systemd.services.wpa_supplicant.wantedBy = lib.mkOverride 10 [ "default.target" ];
    networking.interfaces.end0.ipv4 = {
      addresses = [
        {
          address = "192.168.1.30"; # Your static IP address
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


    # services.udev.extraRules = ''ACTION=="add", SUBSYSTEM=="net", KERNEL=="can*", DRIVERS=="kvaser_usb", ATTRS{idVendor}=="0bfd", ATTRS{idProduct}=="0110", NAME="can2", RUN+="${ipCmd} link set can2 up type can bitrate 500000 && ${ipCmd} link set up can2"'';
    networking.can.interfaces = {
      # can_kv = {
      #   # kvaser usb CAN
      #   bitrate = 500000; #
      # };
      can_secondary = {
        # aux SPI CAN
        bitrate = 500000;
      };
      can_primary = {
        # car / telem CANnix build .#nixosConfigurations.tcu.config.system.build.toplevel
        bitrate = 1000000;
      };
    };

    systemd.network.links = {
        "10-ht09-can-primary" = {
          matchConfig = { Path = "platform-1f00050000.spi-cs-0"; };
          linkConfig.Name = "can_primary";
        };

        "10-ht09-can-secondary" = {
          matchConfig = { Path = "platform-1f00050000.spi-cs-1"; };
          linkConfig.Name = "can_secondary";
        };
        # "10-ht09-can-kv" = {
        #   matchConfig = { Property = "ID_MODEL=Kvaser_U100"; };
        #   linkConfig.Name = "can_kv"; # kvaser CAN
        # };
      };

    hardware = {
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
                enable = true;
                value = "off";
              };
            };

            dt-overlays = {
              mcp2515-can0 = { # can primary
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
