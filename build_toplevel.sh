#!/bin/bash
set -e
echo "Building top level..."
nix build .#nixosConfigurations.tcu.config.system.build.toplevel --system aarch64-linux
echo "Copying closure..."
nix-copy-closure --to nixos@192.168.203.1 result/
