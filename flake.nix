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
    hytech_data_acq.url = "github:RCMast3r/data_acq";
    raspberry-pi-nix.url = "github:tstat/raspberry-pi-nix";

  };
  outputs = { self, nixpkgs, hytech_data_acq, raspberry-pi-nix }: rec {

    shared_config = {
      nixpkgs.overlays = [ (hytech_data_acq.overlays.default) ];

      # nixpkgs.config.allowUnsupportedSystem = true;
      nixpkgs.hostPlatform.system = "aarch64-linux";

      systemd.services.sshd.wantedBy =
        nixpkgs.lib.mkOverride 40 [ "multi-user.target" ];
      services.openssh = { enable = true; };

      virtualisation.docker.enable = true;
      users.users.nixos.extraGroups = [ "docker" ];
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
      networking.useDHCP = false;
      # users.extraUsers.nixos.openssh.extraConfig = "AddressFamily = any";
      networking.hostName = "hytech-pi";
      networking.firewall.enable = false;
      networking.wireless = {
        enable = true;
        interfaces = [ "wlan0" ];
        networks = { "yo" = { psk = "11111111"; }; };
      };

      # networking.defaultGateway.address = "192.168.84.243";
      networking.interfaces.wlan0.ipv4.addresses = [{
        address = "192.168.143.69";
        prefixLength = 24;
      }];

      networking.interfaces.end0.ipv4 = {
        addresses = [
          {
            address = "192.168.1.100"; # Your static IP address
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
      networking.nameservers = [ "192.168.1.1" ]; # Your DNS server, often the gateway

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

    pi4_config_normal = { pkgs, lib, ... }:
      {
        nix.settings.require-sigs = false;
        users.users.nixos.group = "nixos";
        users.users.root.initialPassword = "root";
        users.users.nixos.password = "nixos";
        users.users.nixos.extraGroups = [ "wheel" ];
        users.groups.nixos = { };
        users.users.nixos.isNormalUser = true;

        system.activationScripts.createRecordingsDir = lib.stringAfter [ "users" ] ''
          mkdir -p /home/nixos/recordings
          chown nixos:users /home/nixos/recordings
        '';
      };
    nixosConfigurations.rpi4-base = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        (
          { pkgs, ... }: {
            config = {
              environment.systemPackages = [
                pkgs.can-utils
              ];
              sdImage.compressImage = false;
            };
          }
        )
        (shared_config)
        pi4_config_normal
        raspberry-pi-nix.nixosModules.raspberry-pi
      ];
    };
    # shoutout to https://github.com/tstat/raspberry-pi-nix absolute goat
    nixosConfigurations.rpi4 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./modules/data_acq.nix
        ./modules/can_network.nix
        (
          { pkgs, ... }: {
            config = {
              environment.systemPackages = [
                pkgs.can-utils
              ];
              sdImage.compressImage = false;
            };
            options = {
              services.data_writer.options.enable = true;
            };
          }
        )
        (can_config)
        (shared_config)
        raspberry-pi-nix.nixosModules.raspberry-pi
        pi4_config_normal

        ./hw/tcu_hardware.nix
      ];
    };
    nixosConfigurations.rpi3-mini-tcu = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./modules/data_acq.nix
        ./modules/can_network.nix
        (
          { pkgs, ... }: {
            config = {
              environment.systemPackages = [
                pkgs.can-utils
              ];
              sdImage.compressImage = false;
            };
            options = {
              services.data_writer.options.enable = true;
            };
          }
        )
        (can_config)
        (shared_config)
        raspberry-pi-nix.nixosModules.raspberry-pi
        pi4_config_normal
        ./hw/mini_tcu_hardware.nix
      ];
    };
    
    images.rpi4-base = nixosConfigurations.rpi4-base.config.system.build.sdImage;
    images.rpi4 = nixosConfigurations.rpi4.config.system.build.sdImage;
    images.rpi3-mini-tcu = nixosConfigurations.rpi3-mini-tcu.config.system.build.sdImage;

    defaultPackage.aarch64-linux = nixosConfigurations.rpi4.config.system.build.toplevel;
  };
}
