{
  description = "Build image";
  nixConfig = {
    extra-substituters = [ "https://raspberry-pi-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/8bf65f17d8070a0a490daf5f1c784b87ee73982c";
    hytech_data_acq.url = "github:hytech-racing/data_acq/frontend-dropdown";
    hytech_data_acq.inputs.ht_can_pkg_flake.url = "github:hytech-racing/ht_can/46";
    raspberry-pi-nix.url = "github:tstat/raspberry-pi-nix";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs = { self, nixpkgs, hytech_data_acq, raspberry-pi-nix, nixos-generators }: rec {


    shared_config = {
      nixpkgs.overlays = hytech_data_acq.overlays.aarch64-linux ++
        [
          (self: super: {
            linux-router = super.linux-router.override {
              useQrencode = false;
            };
          })
        ];

      nix.settings.require-sigs = false;
      users.users.nixos.group = "nixos";
      users.users.root.initialPassword = "root";
      users.users.nixos.password = "nixos";
      users.groups.nixos = { };
      users.users.nixos.isNormalUser = true;

      system.activationScripts.createRecordingsDir = nixpkgs.lib.stringAfter [ "users" ] ''
        mkdir -p /home/nixos/recordings
        chown nixos:users /home/nixos/recordings
      '';

      systemd.services.sshd.wantedBy =
        nixpkgs.lib.mkOverride 40 [ "multi-user.target" ];
      services.openssh = { enable = true; };

      virtualisation.docker.enable = true;
      users.users.nixos.extraGroups = [ "docker" "wheel" ];
      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };
      services.openssh.listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 22;
        }
        {
          addr = ":";
          port = 22;
        }
      ];
      users.extraUsers.nixos.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSt9Z8Qdq068xj/ILVAMqmkVyUvKCSTsdaoehEZWRut rcmast3r1@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhMu3LzyGPjh0WkqV7kZYwA+Hyd2Bfc+1XQJ88HeU4A rcmast3r1@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZRFnx0tlpUAFqnEqP2R/1y8oIAPXhL2vW/UU727vw8 eddsa-key-Pranav"
      ];
      networking.useDHCP = true;
      networking.hostName = "hytech-pi";
      networking.firewall.enable = false;
      networking.wireless = {
        enable = true;
        interfaces = [ "wlan0" ];
      };
      networking.extraHosts =
        ''
          192.168.203.1 hytech-pi
        '';


      systemd.services.wpa_supplicant.wantedBy =
        nixpkgs.lib.mkOverride 10 [ "default.target" ];
      # NTP time sync.
      services.timesyncd.enable = true;
      programs.git = {
        enable = true;
        config = {
          user.name = "Ben Hall";
          user.email = "rcmast3r1@gmail.com";
        };
      };
    };

    can_config = {
      networking.can.enable = true;

      networking.can.interfaces = {
        can0 = {
          bitrate = 500000;
        };
      };
    };

    pi4_config = { pkgs, lib, ... }:
      {
        nixpkgs.hostPlatform.system = "aarch64-linux";
        networking.wireless = {
          enable = true;
          interfaces = [ "wlan0" ];
          networks = { "yo" = { psk = "11111111"; }; };
        };
        networking.extraHosts =
          ''
            192.168.203.1 hytech-pi
          '';

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
      };


    vmConfig = { config, pkgs, ... }: {
      # Configure the VirtualBox VM settings
      virtualisation.virtualbox.guest.enable = true;
      boot.kernelModules = [ "vboxguest" "vboxsf" ];
      services.getty.autologinUser = "root";
      users.users.root.password = "root";
    };

    # shoutout to https://github.com/tstat/raspberry-pi-nix absolute goat
    nixosConfigurations.tcu = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit self; };
      modules = [
        ./modules/data_acq.nix
        ./modules/can_network.nix
        ./modules/linux_router.nix
        ./modules/data_acq_frontend.nix
        (
          { pkgs, ... }: {
            config = {
              environment.etc."hytech_nixos".source = self;
              environment.systemPackages = [
                pkgs.can-utils
                pkgs.ethtool
                pkgs.python3
                pkgs.nodePackages.serve
                pkgs.getconf
              ];
            };
            options = {
              services.data_writer.options.enable = true;
              services.linux_router.options.enable = true;
              services.linux_router.options.host-ip = "192.168.203.1";
              services.user.data_acq_frontend.enable = true;

            };

          }
        )
        (can_config)
        (shared_config)
        raspberry-pi-nix.nixosModules.raspberry-pi
        pi4_config
      ];
    };

    # Use nixos-generate to create the VM
    nixosConfigurations.vbi = nixos-generators.nixosGenerate {
      system = "x86_64-linux";
      format = "virtualbox";
      modules = [
        ./modules/data_acq.nix
        ./modules/data_acq_frontend.nix
        (
          { pkgs, ... }: {
            config = {
              environment.systemPackages = [
                pkgs.python3
                pkgs.nodejs
              ];
            };
            options = {
              services.data_writer.options.enable = true;
              # services.data_acq_frontend.enable = true;
              services.user.data_acq_frontend.options.enable = true;
            };

          }
        )
        (shared_config)
        vmConfig
      ];
    };


    images.rpi4 = nixosConfigurations.rpi4.config.system.build.sdImage;
    images.rpi3 = nixosConfigurations.rpi3.config.system.build.sdImage;
    defaultPackage.aarch64-linux = nixosConfigurations.rpi4.config.system.build.toplevel;
    images.tcu = nixosConfigurations.tcu.config.system.build.sdImage;
    tcu_top = nixosConfigurations.tcu.config.system.build.toplevel;
  };
}
