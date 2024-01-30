{ config, lib, pkgs, name, ... }:
with lib; with types; # use the functions from lib, such as mkIf
let
in
{
  options = {
    
    source = mkOption {
      type = (submodule (import ./vm-dev-address.nix {config = config; lib = lib; pkgs = pkgs; }));
    };
    
    target = mkOption {
      type = (submodule (import ./vm-dev-address.nix {config = config; lib = lib; pkgs = pkgs; }));
      default = {};
    };
  };
}

