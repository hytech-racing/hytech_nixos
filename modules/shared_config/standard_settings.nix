# contains the shared configuration for nix, the nixos user on tcu, standard programs
{ config, lib, ... }:
{
  config = {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.require-sigs = false;
    users.users.nixos.group = "nixos";
    users.users.root.initialPassword = "root";
    users.users.nixos.password = "nixos";
    users.groups.nixos = { };
    users.users.nixos.extraGroups = [ "wheel" "dialout" ];

    users.users.nixos.isNormalUser = true;
    system.stateVersion = "23.11";
    system.activationScripts.createRecordingsDir = lib.stringAfter [ "users" ] ''
      mkdir -p /home/nixos/recordings
      mkdir -p /home/nixos/aero_sensor_recordings
      chown nixos:users /home/nixos/recordings
      chown nixos:users /home/nixos/aero_sensor_recordings
    '';
    users.extraUsers.nixos.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSt9Z8Qdq068xj/ILVAMqmkVyUvKCSTsdaoehEZWRut rcmast3r1@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhMu3LzyGPjh0WkqV7kZYwA+Hyd2Bfc+1XQJ88HeU4A rcmast3r1@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZRFnx0tlpUAFqnEqP2R/1y8oIAPXhL2vW/UU727vw8 eddsa-key-Pranav"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFBuvjOko9dUmM1Dd44xwlNdoE7y+E8UEu1mTgxxj0W hytech@nixos"
    ];
  programs.git = {
    enable = true;
    config = {
      user.name = "Ben Hall";
      user.email = "rcmast3r1@gmail.com";
    };
  };
  };
}
