#!/bin/bash
set -e
# nix build .#tcu_top --system aarch64-linux --override-input hytech_params ../HT_params
nix build .#tcu_top --system aarch64-linux
# nix-copy-closure --to nixos@192.168.1.69 result/