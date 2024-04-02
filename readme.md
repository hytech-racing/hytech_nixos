### how to update CAN library on car

1. ssh into
pre-reqs:

- for non-nixOs systems that have the nix package manager installed:
    - enable nix flakes
    - install `qemu-user-static` package then in `/etc/nix/nix.conf` add:
        `extra-platforms = aarch64-linux arm-linux` and `trusted-users = root <username>` and then restart `nix-daemon.service`


- to build the flake defined image: `nix build .#images.rpi4 --system aarch64-linux`

typical workflow:

1. build with 
    - `nix build .#tcu_top --system aarch64-linux` for the tcu
2. `nix-copy-closure --to nixos@192.168.143.69 result/` (will have store path as part of output to switch to)
3. (ssh into pi)
4. `sudo /nix/store/<hash>-nixos-system-<version>/bin/switch-to-configuration switch`
5. profit

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
