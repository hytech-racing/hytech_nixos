### user docs for HyTech's pi

#### ports
`8000`: param server
`8001`: file server
`6969`: old frontend


#### starting and stopping recording

Connect to http://192.168.203.1:6969/ once on the `ht09` wifi.

#### getting files off the car

1. connect to the pi's local wifi network named `ht09`
2. open a command prompt that has ssh installed (powershell or bash)
3. `scp nixos@192.168.203.1:/home/nixos/recordings/* .` (password is `nixos`)


#### fixing MCAP files that werent properly closed
you may need to fix the mcap files as when they are not correctly closed (when we turn of LV it doesnt close the file correctly)
### developer deployment and usage
pre-reqs:

- for non-nixOs systems that have the nix package manager installed:
    - enable nix flakes
    - install `qemu-user-static` package then in `/etc/nix/nix.conf` add:
        `extra-platforms = aarch64-linux arm-linux` and `trusted-users = root <username>` and then restart `nix-daemon.service`


- to build the flake defined image: `nix build .#images.rpi4 --system aarch64-linux`

typical workflow:

1. Pull from Github
2. Update nix flake with `nix flake update`
4. build with 
<<<<<<< Updated upstream
    - `nix build .#nixosConfigurations.tcu.config.system.build.toplevel --builders "ssh://ubuntu@100.125.71.41 aarch64-linux - - - big-parallel" --system aarch64-linux --system-features big-parallel --max-jobs 0 -L`
5. connect to `ht<car-number>` wifi network while drivebrain is on
=======
    - sd image: `nix build .#nixosConfigurations.tcu.config.system.build.sdImage --builders "ssh://ubuntu@100.125.71.41 aarch64-linux - - - big-parallel" --system aarch64-linux --system-features big-parallel --max-jobs 0 -L`
    - top level (when you dont need to re-image the pi, you can most of the time just use this):
    `nix build .#nixosConfigurations.tcu.config.system.build.toplevel --builders "ssh://ubuntu@100.125.71.41 aarch64-linux - - - big-parallel" --system aarch64-linux --system-features big-parallel --max-jobs 0 -L` 
5. connect to `ht09` wifi network while tcu is on
>>>>>>> Stashed changes
6. `nix-copy-closure --to nixos@192.168.203.1 result/` (will have store path as part of output to switch to. this exact store path will be switched to)
7. (ssh into pi `ssh nixos@192.168.203.1`) password is `nixos`
8. `sudo /nix/store/<hash>-nixos-system-<version>/bin/switch-to-configuration switch`
9. profit


notes:

writing to sd card with `dd`. the `/dev/sd<>` should just point to the device and not an existing partition on the device (eg: `/dev/sdd`):
```
zstdcat <file.img.zst in result/> | sudo dd of=/dev/sd<change-me-pls> bs=4M status=progress oflag=direct
```

## weekly SD image 

every week a new SD image is created as a release artifact from this repo from the master branch. use the command above to image the pi's sd card.

