{ config, lib, pkgs, name, ... }:
with lib; with types; # use the functions from lib, such as mkIf
let
  x = "";
in
{
  options = {
    name = mkOption {
      type = str;
      description = "the name of the network adapter (the actual interface name will be derived from the vm-name and this)";
    };
    
    mac = mkOption {
      type = str;
      default = null;
      description = "the mac address of the nic";
    };
    
    # for simple bridges to real physical interfaces
    physical = mkOption {
      type = nullOr str;
      default = null;
      description = "the host nic to attach to";
    };
    
    # for attachment to existing bridge interfaces.
    bridge = mkOption {
      type = nullOr (submodule {
        options = {
          name = mkOption {
            type = nullOr str;
            default = null;
          };
          /*
          vlan = mkOption {
            type = nullOr int;
            default = null;
          };
          */
        };
      });
      default = null;
    };
    /*
    # creates a nat network exclusively for this VM
    nat = mkOption {
      
    }*/
    
    # for attachment to a predefined libvirt network
    network = mkOption {
      type = nullOr (submodule {
        options = {
          name = mkOption {
            type = nullOr str;
            default = null;
          };
          portgroup = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      });
      default = null;
    };
    
    /*
    # for anything more complicated than simple switches or direct host networks
    direct-switch = mkOption {
      type = nullOr (submodule {
        options = {
          name = mkOption {
            type = nullOr str;
            default = null;
          };
          vlan = mkOption {
            type = nullOr int;
            default = null;
          };
        };
      });
      default = null;
    };
    */
    
    # for attachment to an open-viswitch
    switch = mkOption {
      type = nullOr (submodule {
        options = {
          name = mkOption {
            type = nullOr str;
            default = null;
          };
          vlan = mkOption {
            type = nullOr int;
            default = null;
          };
        };
      });
      default = null;
    };
    
    # creates a host-only network exclusively for this VM
    host = mkOption {
      type = nullOr (submodule {
        options = {
          host-address = mkOption {
            type = nullOr str;
            default = null;
            description = "the ip address of the host";
          };
          guest-address = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              The ip address of the guest. 
              
              this will only be applied if the guest requests its address via DHCP.
            '';
          };
          dhcp-lowest = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              The first dhcp address. Defaults to guest-address.
              
              this will only be applied if the guest requests its address via DHCP.
            '';
          };
          dhcp-highest = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              The last dhcp address. Defaults to guest-address.
              
              this will only be applied if the guest requests its address via DHCP.
            '';
          };
          netmask = mkOption {
            type = str;
            default = "255.255.255.0";
          };
          prefix-length = mkOption {
            type = int;
            default = 24;
          };
        };
      });
      default = null;
      description = "to be used for host-only networking";
    };
    
    # creates a routed network exclusively for this VM
    routed = mkOption {
      type = nullOr (submodule {
        options = {
          
          dev = mkOption {
            type = nullOr str;
            default = null;
            description = "the device to route traffic on";
          };
          
          host-address = mkOption {
            type = nullOr str;
            default = null;
            description = "the ip address of the host";
          };
          guest-address = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              The ip address of the guest. 
              
              this will only be applied if the guest requests its address via DHCP.
            '';
          };
          dhcp-lowest = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              The first dhcp address. Defaults to guest-address.
              
              this will only be applied if the guest requests its address via DHCP.
            '';
          };
          dhcp-highest = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              The last dhcp address. Defaults to guest-address.
              
              this will only be applied if the guest requests its address via DHCP.
            '';
          };
          netmask = mkOption {
            type = str;
            default = "255.255.255.0";
          };
          prefix-length = mkOption {
            type = int;
            default = 24;
          };
        };
      });
      default = null;
      description = "to be used for host-only networking";
    };
    
  };
}

