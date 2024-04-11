{config, pkgs, modulesPath, ...}

with lib;
let
{
    environment.systemPackages = with pkgs; [
    static-web-server
    ];
    services.httpd.enable = true;
}

in {

  config = {
    services.static-web-server = {
    enable = true;
    root = "./path/to/MCAP/files";
    };
  };
  
}
