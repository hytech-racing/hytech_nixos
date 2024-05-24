{ lib, pkgs, config, ... }:
with lib;
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.data_writer;

in
{
  # options.services.data_writer = {
  #   mcu-ip = mkOption {
  #     type = types.str;
  #     default = "192.168.1.30";
  #   };
  #   send-to-mcu-port = mkOption {
  #     type = types.int;
  #     default = 20000;
  #   };
  #   recv-from-mcu-port = mkOption {
  #     type = types.int;
  #     default = 20001;
  #   };
  #   recv-ip = mkOption {
  #     type = types.str;
  #     default = "192.168.1.69";
  #   };
  # };
  config = {
    # https://nixos.org/manual/nixos/stable/options.html search for systemd.services.<name>. to get list of all of the options for 
    # new systemd services
    systemd.services.data_writer = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.After = [ "network.target" ];
      # https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html serviceconfig
      serviceConfig.ExecStart =
        "${pkgs.py_data_acq_pkg}/bin/runner.py ${pkgs.proto_gen_pkg}/bin ${pkgs.ht_can_pkg}";
      serviceConfig.ExecStop = "/bin/kill -9 $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}
