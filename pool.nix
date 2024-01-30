{ config, lib, pkgs, name, ... }:
with lib; with types; # use the functions from lib, such as mkIf
let
  x = "";
in
{
  # virsh pool-define-as --name default --source-name data/libvirt-storage --type zfs
  options = {
    
    
    description = mkOption {
      type = nullOr str;
      default = null;
    };
    
    source = mkOption {
      type = str;
      default = null;
      description = "the source name (the zfs dataset name for example)";
    };
    
    type = mkOption {
      type = str;
      default = "zfs";
      description = "the type of the pool (e.g. zfs)";
    };
    
    start = mkOption {
      type = bool;
      default = true;
      description = "whether virtm should enable AND start the pool";
    };
    
  };
}

