{
  description = "Build image";
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" "https://rcmast3r.cachix.org"];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" "rcmast3r.cachix.org-1:dH22dF877RZ1j7uvAgqnQWNChxdQDeqgBRWpXzoi84c="];
  };

  inputs = {
    ht_proto.url = "github:hytech-racing/HT_proto/2025-05-07T00_27_37";
    ht_can.url = "github:hytech-racing/ht_can/159";
    hytech_data_acq.url = "github:hytech-racing/data_acq";
    hytech_data_acq.inputs.ht_can_pkg_flake.follows = "ht_can";
    drivebrain-software.url = "github:hytech-racing/drivebrain_software/dev/v1.1.0";
    drivebrain-software.inputs.ht_can.follows = "ht_can";
    drivebrain-software.inputs.HT_proto.follows = "ht_proto";
    nix-proto.url = "github:notalltim/nix-proto";
    drivebrain-software.inputs.nix-proto.follows = "nix-proto";
    aero_sensor_logger.url = "github:hytech-racing/aero_sensor_logger/8ff36ab9256d6f22ad04aff68c3fabc5f2de796d";
    hytech_params_server.url = "github:hytech-racing/HT_params/2024-05-26T15_33_34";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    nixpkgs.url = "github:NixOS/nixpkgs";
    nixpkgs.follows = "raspberry-pi-nix/nixpkgs";

    
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-shell.url = "github:Mic92/nixos-shell";
  };

  outputs = { self, nixpkgs, hytech_data_acq, raspberry-pi-nix, nixos-generators, home-manager, hytech_params_server, aero_sensor_logger, drivebrain-software, ...}@inputs: rec {
    
    nixpkg_overlays =
      {
        nixpkgs.overlays = aero_sensor_logger.overlays.aarch64-linux ++ hytech_params_server.overlays.aarch64-linux ++ hytech_data_acq.overlays.aarch64-linux ++
          [
            (self: super: {
              linux-router = super.linux-router.override {
                useQrencode = false;
              };
            })
            drivebrain-software.overlays.default
            drivebrain-software.inputs.easy_cmake.overlays.default
            drivebrain-software.inputs.nebs-packages.overlays.default
            drivebrain-software.inputs.vn_driver_lib.overlays.default

          ];
      };

    shared_config_modules = [
      ./modules/shared_config/environment.nix
      ./modules/shared_config/networking.nix
      ./modules/shared_config/standard_settings.nix
      ./modules/shared_config/standard_services.nix
      ./modules/software_config/drivebrain_software.nix
    ];

    tcu_config_modules = [
      ./modules/linux_router.nix
      ./modules/hardware_config/tcu_config.nix
    ];

    hytech_service_modules = [
      ./modules/can_network.nix
      ./modules/simple_http_server.nix
      ./modules/grpcui.nix
    ];

    nixosConfigurations.tcu = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      specialArgs = { inherit self; };
      modules =
        tcu_config_modules ++
        hytech_service_modules ++
        shared_config_modules ++ [
          (nixpkg_overlays)
          home-manager.nixosModules.home-manager
          inputs.raspberry-pi-nix.nixosModules.raspberry-pi
          inputs.raspberry-pi-nix.nixosModules.sd-image
          (
            { config, options, ... }: rec {
              nixpkgs.hostPlatform.system = "aarch64-linux";

              services.linux_router.host-ip = "192.168.203.1";
              services.http_server.port = 8001;
              drivebrain-service.enable = true;
              simple_http_server.enable = true;
              services.grpcui.enable = true;
              tcu_config.enable = true;
              hytech-nixos-environment.enable = true;
              hytech-nixos-networking.enable = true;
              standard-services.enable = true;
              standard-settings.enable = true;
              linux_router.enable = true;

              raspberry-pi-nix.libcamera-overlay.enable = false;
              raspberry-pi-nix.board = "bcm2712";
              # raspberry-pi-nix.kernel-version = "v6_12_17";

            }
          )
        ];
    };

    test-shell = {
      system = "x86_64-linux";
      specialArgs = { inherit self; };
      modules =
        shared_config_modules ++
        hytech_service_modules ++
        [
          inputs.nixos-shell.nixosModules.nixos-shell
          (nixpkg_overlays)
          (
            { config, ... }: {
              virtualisation.forwardPorts = [ 
                { from = "host"; host.port = 2222; guest.port = 22; }
                { from = "host"; host.port = 8001; guest.port = 8001; }
                { from = "host"; host.port = 8000; guest.port = 80; }
              ];
              networking.interfaces.eth0.ipv4 = {
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
              services.http_server.port = 8001;
              drivebrain-service.enable = true;
              simple_http_server.enable = true;
              services.grpcui.enable = true;
              hytech-nixos-environment.enable = true;
              hytech-nixos-networking.enable = true;
              standard-services.enable = true;
              standard-settings.enable = true;
            }
          )
        ];
    };

    packages = import nixpkgs{
      system = "x86_64-linux";
      overlays = nixpkg_overlays.nixpkgs.overlays;

    };
    # virtualbox_vm_modules = { modules = support_vm_config.modules ++ [ ./modules/vm_config/virtualbox_config.nix ]; };
    # cc_vm_modules = { modules = support_vm_config.modules ++ [ ./modules/vm_config/basic_vm_hw.nix ]; };
    # Use nixos-generate to create the VMs
    # nixosConfigurations.vbi = nixos-generators.nixosGenerate (support_vm_config // virtualbox_vm_modules // { format = "virtualbox"; });
    nixosConfigurations.test-shell = nixpkgs.lib.nixosSystem (test-shell );

    images.tcu = nixosConfigurations.tcu.config.system.build.sdImage;
    tcu_top = nixosConfigurations.tcu.config.system.build.toplevel;
    config_test = nixosConfigurations.tcu.config.hardware.raspberry-pi.config-output;
    shell = nixosConfigurations.test-shell.config.system.build.nixos-shell;
  };
}