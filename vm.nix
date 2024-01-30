{ config, lib, pkgs, name, ... }:
with lib; with types; # use the functions from lib, such as mkIf
let
  x = "";
in
{
  options = {
    
    start = mkOption {
      type = bool;
      default = false;
      description = "whether libvirt should start vm";
    };
    start-delay = mkOption {
      type = int;
      default = 0;
    };
    
    efi = mkOption {
      type = bool;
      default = false;
      description = "use EFI (in contrast to BIOS)";
    };
    
    nested = mkOption {
      type = bool;
      default = false;
      description = "the effect of this option is to pass through at least part of host's CPU specification, so that virtualisation will be enabled inside the VM as well. For this to work, you also need to enable nested virtualisation globally for virtm or set the required kernel parameters (e.g. `kvm_intel nested=1`) yourself.";
    };
    
    description = mkOption {
      type = nullOr str;
      default = null;
    };
    
    
    extra-devices = mkOption {
      type = listOf str;
      default = [];
    };
    extra-config = mkOption {
      type = listOf str;
      default = [];
    };
    extra-features = mkOption {
      type = listOf str;
      default = [];
    };
    
    memory = mkOption {
      type = int;
      default = 4;
      description = "the amount of memory ";
    };
    
    egl-headless = mkOption {
      type = nullOr str;
      default = null;
    };
    
    timeout = mkOption {
      type = int;
      default = 30;
      description = "the timeout before shutting down the VM";
    };
    
    vnc = mkOption {
      type = nullOr (submodule {
        options = {
          enable = mkEnableOption "vnc server for vm";
          port = mkOption {
            type = nullOr int;
            default = null;
          };
          address = mkOption {
            type = nullOr str;
            default = null;
          };
          password = mkOption {
            type = nullOr str;
            default = null;
          };
          keymap = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      });
      default = null;
    };
    
    memory-size-unit = mkOption {
      type = str;
      default = "GiB";
      description = "the size";
    };
    
    networking = mkOption {
      type = listOf (submodule (import ./vm-nic.nix));
      default = {};
    };
    
    
    disks = mkOption {
      type = attrsOf (submodule (import ./vm-disk.nix));
      default = {};
    };
    
    usb = mkOption {
      type = attrsOf (submodule (import ./vm-usb.nix));
      default = {};
    };
    pci = mkOption {
      type = attrsOf (submodule (import ./vm-pci.nix));
      default = {};
    };
    
    scsi = mkOption {
      type = attrsOf (submodule (import ./vm-scsi.nix));
      default = {};
    };
    
    cds = mkOption {
      type = attrsOf (submodule (import ./vm-cd.nix));
      default = {};
    };
    
    shares = mkOption {
      type = attrsOf (submodule ({
        options = {
          source = mkOption {
            type = str;
          };
        };
      }));
      default = {};
    };
    
  };
}

