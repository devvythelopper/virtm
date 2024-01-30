{ config, lib, pkgs, name, ... }:
with lib; with types; # use the functions from lib, such as mkIf
let
  x = "";
in
{
  options = {
    
    image = mkOption {
      type = unspecified;
      default = null;
      description = "iso image...";
    };
    
    target = mkOption {
      type = (submodule (import ./vm-dev-address.nix {config = config; lib = lib; pkgs = pkgs; }));
      default = {};
    };
  };
}

