### user docs for HyTech's pi

#### ports
`8000`: param server
`8001`: file server
`6969`: old frontend


#### starting and stopping recording

Connect to http://192.168.203.1:6969/ once on the `ht08` wifi.

#### getting files off the car

1. connect to the pi's local wifi network named `ht08`
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
    - `nix build .#tcu_top --system aarch64-linux` for the tcu
5. connect to `ht08` wifi network while tcu is on
6. `nix-copy-closure --to nixos@192.168.203.1 result/` (will have store path as part of output to switch to. this exact store path will be switched to)
7. (ssh into pi `ssh nixos@192.168.203.1`) password is `nixos`
8. `sudo /nix/store/<hash>-nixos-system-<version>/bin/switch-to-configuration switch`
9. profit


notes:

pushing to cachix (via emulated aarch64-linux):
(after following the registration steps for pushing)
```
nix build --system aarch64-linux --json \
  | jq -r '.[].outputs | to_entries[].value' \
  | cachix push rcmast3r
```


writing to sd card with `dd`. the `/dev/sd<>` should just point to the device and not an existing partition on the device (eg: `/dev/sdd`):
```
zstdcat <file.img.zst in result/> | sudo dd of=/dev/sd<change-me-pls> bs=4M status=progress oflag=direct
```
