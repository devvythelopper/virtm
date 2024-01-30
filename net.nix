{ config, lib, pkgs, name, ... }:
with lib; with types; # use the functions from lib, such as mkIf
{
  options = {
    
    start = mkOption {
      type = bool;
      default = true;
    };
    
    nat = mkOption {
      type = nullOr (submodule {
        options = {
          start-port = mkOption {
            type = int;
            default = 1024;
          };
          end-port = mkOption {
            type = int;
            default = 65535;
          };
        };
      });
      default = null;
    };
    routed = mkOption {
      type = nullOr (submodule {
        options = {
          dev = mkOption {
            type = str;
          };
        };
      });
      default = null;
    };
    host-address = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        The host's address. 
      '';
    };
    dhcp-lowest = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        The first dhcp address. 
      '';
    };
    dhcp-highest = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        The last dhcp address. 
      '';
    };
    netmask = mkOption {
      type = str;
      default = "255.255.255.0";
    };
  };
}