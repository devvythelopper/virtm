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
      description = "an optional qemu image on which the disk should be based upon (only used at disk creation time)";
    };
    
    dev = mkOption {
      type = nullOr str;
      default = null;
      description = "fill out to attach an existing block device.";
    };
    
    
    size = mkOption {
      type = int;
      default = 8;
      description = "the size, defaults to 8, so that a nix-style system update of a simple server can be performed without problems (which requires disk space for the old system and the new, e.g. 2 x 4GiB)";
    };
    
    size-unit = mkOption {
      type = str;
      default = "GiB";
      description = "the size";
    };
    
    pool = mkOption {
      type = str;
      default = "default";
    };
  };
}

