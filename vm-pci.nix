{ config, lib, pkgs, name, ... }:
with lib; with types; # use the functions from lib, such as mkIf
let
in
{
  options = {
    
    domain = mkOption {
      type = str;
      # default = null;
    };
    
    bus = mkOption {
      type = str;
      # default = null;
    };
    
    slot = mkOption {
      type = str;
      # default = null;
    };
    
    function = mkOption {
      type = str;
      # default = null;
    };
    
  };
}

