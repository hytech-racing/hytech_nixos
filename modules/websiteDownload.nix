# source: https://nix.dev/tutorials/module-system/module-system.html

{lib, pkgs, config, ...}: {
    # no need for options
with lib;
let
    cfg = config.services.http_server;
in {

    config = {
        systemd.services.http_server = {
            wantedBy = [ "multi-user.target" ];
            descript = "Allows you to access your MCAP files";
            script = "simple-http-server\n";
            # Dependencies needed when running simple-http-server locally (on Ubuntu): 
            # Sources:
            #   - https://github.com/TheWaWaR/simple-http-server
            #   - https://search.nixos.org/packages?channel=23.11&show=simple-http-server&from=0&size=50&sort=relevance&type=packages&query=simple-http-server
            # Dependencies:
            #   - curl https://sh.rustup.rs -sSf | sh
            #   - sudo apt-get install libssl-dev
            #   - cargo install simple-http-server
            
            confinement.packages = [ pkgs.rustc, pkgs.sslh, pkgs.simple-http-server ];
            serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
            serviceConfig.Restart = "on-failure";
        }

    }

}







}
