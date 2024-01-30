{ config, lib, pkgs, name, ... }:
with lib; with types; # use the functions from lib, such as mkIf
let
in
{
  options = {
    hotplug = mkOption {
      type = bool;
      default = true;
      description = "whether the device should be attached to the running VM. if set to false, the device will only be attached at boot";
    };
    reserve = mkOption {
      type = bool;
      default = false;
      description = "whether the device should be ignored by the host even when the VM is off";
    };
    vendor = mkOption {
      type = str;
      description = "vendor hex";
      example = "0x1234";
    };
    product = mkOption {
      type = str;
      description = "product hex";
      example = "0x1234";
    };
  };
}

