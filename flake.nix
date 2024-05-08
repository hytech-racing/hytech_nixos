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
    hytech_data_acq.url = "github:hytech-racing/data_acq/2024-04-27T00_26_50";
    hytech_data_acq.inputs.ht_can_pkg_flake.url = "github:hytech-racing/ht_can/85";
    hytech_params.url = "github:hytech-racing/HT_params/2024-05-05T22_56_37";
    raspberry-pi-nix.url = "github:tstat/raspberry-pi-nix";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, hytech_data_acq, raspberry-pi-nix, nixos-generators, hytech_params, home-manager }: rec {
    nixpkg_overlays =
      {
        nixpkgs.overlays = hytech_params.overlays.aarch64-linux ++ hytech_data_acq.overlays.aarch64-linux ++
          [
            (self: super: {
              linux-router = super.linux-router.override {
                useQrencode = false;
              };
            })
          ];
      };

    shared_config_modules = [
      ./modules/shared_config/environment.nix
      ./modules/shared_config/networking.nix
      ./modules/shared_config/standard_settings.nix
      ./modules/shared_config/standard_services.nix
    ];

    tcu_config_modules = [
      ./modules/linux_router.nix
      ./modules/hardware_config/tcu_config.nix
    ];

    hytech_service_modules = [
      ./modules/data_acq.nix
      ./modules/can_network.nix
      # ./modules/data_acq_frontend.nix
      ./modules/simple_http_server.nix
      ./modules/param_webserver.nix
    ];

    # shoutout to https://github.com/tstat/raspberry-pi-nix absolute goat
    nixosConfigurations.tcu = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit self; };
      modules =
        tcu_config_modules ++
        hytech_service_modules ++
        shared_config_modules ++ [
          (nixpkg_overlays)
          home-manager.nixosModules.home-manager
          raspberry-pi-nix.nixosModules.raspberry-pi
          (
            { config, ... }: {
                services.linux_router.host-ip = "192.168.203.1";
                # services.user.data_acq_frontend.enable = true;
                services.http_server.port = 8001;
                services.param_webserver.host-recv-ip = "192.168.1.68";
                services.param_webserver.mcu-ip = "192.168.1.30";
                services.param_webserver.param-recv-port = 2002;
                services.param_webserver.param-send-port = 2001;

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
              service_names.url-name = ".car";
              service_names.car-ip = "192.168.86.36";
              service_names.dhcp-start = "192.168.86.37";
              service_names.dhcp-end = "192.168.86.200";
              service_names.default-gateway = "192.168.1.1";
              service_names.dhcp-interfaces = ["enp0s3"];
              services.http_server.port = 8001;
              services.param_webserver.host-recv-ip = "192.168.86.36";
              services.param_webserver.mcu-ip = "192.168.1.30";
              services.param_webserver.param-recv-port = 2002;
              services.param_webserver.param-send-port = 2001;
            }
          )
        ];
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
