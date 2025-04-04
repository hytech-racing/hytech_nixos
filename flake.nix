{
  description = "Build image";
  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };




  inputs = {
    ht_can.url = "github:hytech-racing/ht_can/155";
    hytech_data_acq.url = "github:hytech-racing/data_acq";
    hytech_data_acq.inputs.ht_can_pkg_flake.follows = "ht_can";
    drivebrain-software.url = "github:hytech-racing/drivebrain_software/dev/v1.1.0";
    drivebrain-software.inputs.ht_can.follows = "ht_can";
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
      # ./modules/data_acq.nix
      ./modules/can_network.nix
      ./modules/simple_http_server.nix
    ];

    nixosConfigurations.tcu = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      specialArgs = { inherit self; };
      modules =
        tcu_config_modules ++
        hytech_service_modules ++
        shared_config_modules ++ [
          (nixpkg_overlays)
          # aero_sensor_logger.nixosModules.aarch64-linux.aero-sensor-logger
          home-manager.nixosModules.home-manager
          inputs.raspberry-pi-nix.nixosModules.raspberry-pi
          inputs.raspberry-pi-nix.nixosModules.sd-image
          (
            { config, options, ... }: rec {
              nixpkgs.hostPlatform.system = "aarch64-linux";

              services.linux_router.host-ip = "192.168.203.1";
              services.http_server.port = 8001;
              drivebrain-service.enable = true;
              tcu_config.enable = true;
              hytech-nixos-environment.enable = true;
              hytech-nixos-networking.enable = true;
              standard-services.enable = true;
              standard-settings.enable = true;
              linux_router.enable = true;

              raspberry-pi-nix.libcamera-overlay.enable = false;
              raspberry-pi-nix.board = "bcm2712";

            }
          )
        ];
    };

    support_vm_config = {
      system = "x86_64-linux";
      specialArgs = { inherit self; };
      modules =
        shared_config_modules ++
        hytech_service_modules ++
        [
          (nixpkg_overlays)
          (
            { config, ... }: {
              sdImage.compressImage = false;
              services.data_writer.mcu-ip = "127.0.0.1";
              services.data_writer.recv-ip = "127.0.0.1";
              services.data_writer.send-to-mcu-port = 20001;
              services.data_writer.recv-from-mcu-port = 20002;
              service_names.url-name = ".car";
              service_names.car-ip = "192.168.86.36";
              service_names.dhcp-start = "192.168.86.37";
              service_names.dhcp-end = "192.168.86.200";
              service_names.default-gateway = "192.168.1.1";
              service_names.dhcp-interfaces = [ "enp0s3" ];
              services.http_server.port = 8001;
            }
          )
        ];
    };

    packages = import nixpkgs{
      system = "x86_64-linux";
      overlays = nixpkg_overlays.nixpkgs.overlays;

    };
    virtualbox_vm_modules = { modules = support_vm_config.modules ++ [ ./modules/vm_config/virtualbox_config.nix ]; };
    cc_vm_modules = { modules = support_vm_config.modules ++ [ ./modules/vm_config/basic_vm_hw.nix ]; };
    # Use nixos-generate to create the VMs
    nixosConfigurations.vbi = nixos-generators.nixosGenerate (support_vm_config // virtualbox_vm_modules // { format = "virtualbox"; });
    nixosConfigurations.basic_vm = nixpkgs.lib.nixosSystem (support_vm_config // cc_vm_modules);

    images.tcu = nixosConfigurations.tcu.config.system.build.sdImage;
    tcu_top = nixosConfigurations.tcu.config.system.build.toplevel;
  };
}