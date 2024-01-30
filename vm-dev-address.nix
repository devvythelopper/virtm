{ config, lib, pkgs, ... }:
with lib; with types; # use the functions from lib, such as mkIf
let
in
{
  options = {
    
    type = mkOption {
      type = nullOr str;
      default = null;
    };
    
    controller = mkOption {
      type = nullOr int;
      default = null;
    };
    
    bus = mkOption {
      type = nullOr int;
      default = null;
    };
    
    target = mkOption {
      type = nullOr int;
      default = null;
    };
    
    unit = mkOption {
      type = nullOr int;
      default = null;
    };
  };
}

