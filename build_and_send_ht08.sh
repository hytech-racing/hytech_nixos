#!/bin/bash
set -e
nix build .#tcu_top --system aarch64-linux
nix-copy-closure --to nixos@192.168.203.1 result/