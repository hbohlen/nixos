{ config, pkgs, inputs, lib, hostname, ... }:

# Forward to `home.nix` to match the flake's expected import path.
import ./home.nix { inherit config pkgs inputs lib hostname; }
