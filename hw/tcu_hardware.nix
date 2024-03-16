{ pkgs, lib, ... }:
{
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
            # TODO change this as needed
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
}
