{ config, lib, pkgs, ... }@args:
with lib; with types; # use the functions from lib, such as mkIf
let
  cfg = config.services.virtm;  
  
  
  
  stopVmOwnedNetwork = vm-index: vm-name: vm: nic-index: nic: let 
    # nic = vm.networking[nic-index];
    nic-name = nic.name;
    net-name = if nic.host != null
      then "${builtins.substring 0 4 vm-name}${toString vm-index}-host-${builtins.substring 0 4 nic-name}${toString nic-index}"
      else if nic.switch != null
      then "${builtins.substring 0 4 vm-name}${toString vm-index}-switch-${builtins.substring 0 4 nic-name}${toString nic-index}"
      else "";
    in if nic.host != null || nic.switch != null then
    ''
      set -x
      echo "# ======== stopping network '${net-name}' ========="
      virsh net-destroy '${net-name}' || true
    '' else "";
  
  
  
  mkNetName = vm-index: vm-name: nic-index: nic-name: tp: "${builtins.substring 0 4 vm-name}${toString vm-index}-${tp}-${builtins.substring 0 4 nic-name}${toString nic-index}"; 
  
  mkInterface2 = vm-index: vm-name: vm: nic-index: nic: let
  in mkInterfaceNg vm-index vm-name vm nic-index (nic.name) nic;
  
  
  mkInterfaceNg = vm-index: vm-name: vm: nic-index: nic-name: nic: let 
    net-name = tp: mkNetName vm-index vm-name nic-index nic-name tp;
  in
  ''
      ${
        /*if nic.bridge != null && nic.bridge.device != null then 
          ''
            <interface type="direct">
              ${if nic.bridge.vlan != null
                then ''
                  <vlan><tag id='${toString nic.bridge.vlan}' /></vlan>
                '' else ""}
              <target dev="${nic-name}"/>
              <source dev="${nic.bridge.device}" mode="bridge"/>
              <mac address="${nic.mac}"/>
              <model type="virtio"/>
              <address type="pci" domain="0x0000" bus="0x1F" slot="0x${lib.toHexString nic-index}" function="0x0"/>
            </interface>
          ''
        */
        if nic.physical != null then
          ''
            <interface type="direct">
              <target dev="${builtins.substring 0 4 vm-name}${toString vm-index}-${builtins.substring 0 4 nic-name}${toString nic-index}"/>
              <source dev="${nic.physical}" mode="bridge"/>
              <mac address="${nic.mac}"/>
              <model type="virtio"/>
              <address type="pci" domain="0x0000" bus="0x1F" slot="0x${lib.toHexString nic-index}" function="0x0"/>
            </interface>
          ''
        else if nic.bridge != null then
          ''
            <interface type="bridge">
              <target dev="${builtins.substring 0 4 vm-name}${toString vm-index}-${builtins.substring 0 4 nic-name}${toString nic-index}"/>
              <source bridge="${nic.bridge.name}"/>
              <mac address="${nic.mac}"/>
              <model type="virtio"/>
              <address type="pci" domain="0x0000" bus="0x1F" slot="0x${lib.toHexString nic-index}" function="0x0"/>
            </interface>
          ''
        /*
        else if nic.direct-switch != null then
          ''
            <interface type="bridge">
              <target dev="${builtins.substring 0 4 vm-name}${toString vm-index}-${builtins.substring 0 4 nic-name}${toString nic-index}"/>
              <source bridge="${nic.switch.name}"/>
              <virtualport type='openvswitch'/>
              ${if nic.switch.vlan != null
              then ''
                <vlan><tag id='${toString nic.switch.vlan}' /></vlan>
              '' else ""}
              <mac address="${nic.mac}"/>
              <address type="pci" domain="0x0000" bus="0x1F" slot="0x${lib.toHexString nic-index}" function="0x0"/>
            </interface>
          ''
        */
        else if nic.network != null then
          ''
            <interface type="network">
              <target dev="${builtins.substring 0 4 vm-name}${toString vm-index}-${builtins.substring 0 4 nic-name}${toString nic-index}"/>
              <source network="${nic.network.name}"${if nic.network.portgroup != null then
                '' portgroup="${nic.network.portgroup}"'' else ""}/>
              <mac address="${nic.mac}"/>
              <model type='virtio'/>
              <address type="pci" domain="0x0000" bus="0x1F" slot="0x${lib.toHexString nic-index}" function="0x0"/>
            </interface>
          ''
        else if nic.host != null then
          ''
            <interface type="network">
              <target dev="${builtins.substring 0 4 vm-name}${toString vm-index}-${builtins.substring 0 4 nic-name}${toString nic-index}"/>
              <source network="${net-name "hst"}"/>
              <mac address="${nic.mac}"/>
              <model type="virtio"/>
              <address type="pci" domain="0x0000" bus="0x1F" slot="0x${lib.toHexString nic-index}" function="0x0"/>
            </interface>
          ''
        else if nic.switch != null then
          ''
            <interface type="network">
              <target dev="${builtins.substring 0 4 vm-name}${toString vm-index}-${builtins.substring 0 4 nic-name}${toString nic-index}"/>
              <source network="${net-name "sw"}" portgroup="${if nic.switch.vlan != null then "vlan-${toString nic.switch.vlan}" else "default"}"/>
              <mac address="${nic.mac}"/>
              <model type='virtio'/>
              <address type="pci" domain="0x0000" bus="0x1F" slot="0x${lib.toHexString nic-index}" function="0x0"/>
            </interface>
          ''
        else if nic.routed != null then
          ''
            <interface type="network">
              <target dev="${builtins.substring 0 4 vm-name}${toString vm-index}-${builtins.substring 0 4 nic-name}${toString nic-index}"/>
              <source network="${net-name "rtd"}" />
              <mac address="${nic.mac}"/>
              <model type='virtio'/>
              <address type="pci" domain="0x0000" bus="0x1F" slot="0x${lib.toHexString nic-index}" function="0x0"/>
            </interface>
          ''
        else ""}
  '';
  
  
  mkVmOwnedNetwork = vm-index: vm-name: vm: nic-index: nic: let 
    # nic = vm.networking[nic-index];
    nic-name = nic.name;
    net-name = mkNetName vm-index vm-name nic-index nic-name (
      if nic.host != null then "hst"
      else if nic.switch != null then "sw"
      else if nic.routed != null then "rtd"
      else "");
    xml = pkgs.writeText "libvirt-${net-name}.xml"
      (
        if nic.host != null then 
        # <uuid></uuid>
          ''
            <network  xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
              <name>${net-name}</name>
              <uuid></uuid>
              <bridge name="${net-name}"/>
              <ip address="${nic.host.host-address}" netmask="${nic.host.netmask}">
                <dhcp>
                  <range start="${if nic.host.dhcp-lowest != null then nic.host.dhcp-lowest else nic.host.guest-address}" end="${if nic.host.dhcp-highest != null then nic.host.dhcp-highest else nic.host.guest-address}"/>
                </dhcp>
              </ip>
              <dnsmasq:options>
                ${""/* the guests should not simply know every dns entry in the host's /etc/hosts file... */}
                <dnsmasq:option value="no-hosts"/>
              </dnsmasq:options>
            </network>
          ''
        else if nic.routed != null then 
        # <uuid></uuid>
          ''
            <network  xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
              <name>${net-name}</name>
              <uuid></uuid>
              <bridge name="${net-name}"/>
              <forward mode="route" dev="${nic.routed.dev}"/>
              <ip address="${nic.routed.host-address}" netmask="${nic.routed.netmask}">
                <dhcp>
                  <range start="${if nic.routed.dhcp-lowest != null then nic.routed.dhcp-lowest else nic.routed.guest-address}" end="${if nic.routed.dhcp-highest != null then nic.routed.dhcp-highest else nic.routed.guest-address}"/>
                </dhcp>
              </ip>
              <dnsmasq:options>
                ${""/* the guests should not simply know every dns entry in the host's /etc/hosts file... */}
                <dnsmasq:option value="no-hosts"/>
              </dnsmasq:options>
            </network>
          ''
        else if nic.switch != null then
        # <uuid></uuid>
          ''
            <network  xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
              <name>${net-name}</name>
              <uuid></uuid>
              <forward mode="bridge" />
              <virtualport type='openvswitch'/>
              <bridge name="${nic.switch.name}"/>
              ${if nic.switch.vlan != null
              then 
              
              #  <vlan trunk="yes">
              #    <tag id='${toString nic.switch.vlan}' />
              #  </vlan>
              ''
                <portgroup name='vlan-${toString nic.switch.vlan}'>
                  <vlan><tag id='${toString nic.switch.vlan}' nativeMode="untagged"/></vlan>
                </portgroup>
              '' else ''
                <portgroup name='default'>
                </portgroup>
              ''}
              <dnsmasq:options>
                ${""/* the guests should not simply know every dns entry in the host's /etc/hosts file... */}
                <dnsmasq:option value="no-hosts"/>
              </dnsmasq:options>
            </network>
          ''
        else ""
      );
  in if nic.host != null || nic.switch != null || nic.routed != null then
  mkDefineNetworkScript net-name xml true else "";
  
  
  
  
  
  
  mkDisk = vm-name: vm: disk-name: let disk = vm.disks."${disk-name}"; in 
    if disk.dev != null then ''
      <disk type="block" device="disk">
        <driver name="qemu" type="raw" cache="none"/>
        <source dev="${disk.dev}"/>
        <target dev="${disk-name}" bus="virtio"/>
      </disk>
    '' else ''
      <disk type="volume">
        <source pool="${disk.pool}" volume="vm-${vm-name}-${disk-name}"/>
        <target dev="${disk-name}" bus="virtio"/>
      </disk>
    '';
  
  mkCd = vm-name: vm: disk-index: disk-name: let dev = vm.cds."${disk-name}"; in ''
      <disk type="file" device="cdrom">
        ${optionalString (dev.image != null) ''
          <source file="${dev.image}" />
        ''}
        <target dev="${disk-name}" bus="ide" tray="open"/>
        <readonly/>
        <address type="drive" ${optionalString (dev.target.controller != null) ''controller="${toString dev.target.controller}" ''}${optionalString (dev.target.bus != null) ''bus="${toString dev.target.bus}" ''}unit="${toString (if dev.target.unit != null then dev.target.unit else disk-index)}"/>
      </disk>
    '';
    # <address type="drive" controller="${toString disk.controller-id}" bus="${toString disk.bus-id}" target="${toString disk.target-id}" unit=""/>
  
  mkUsbPassthrough = vm-name: vm: dev-index: dev-name: let dev = vm.usb."${dev-name}"; in ''
    <hostdev mode='subsystem' type='usb'>
      <source startupPolicy='optional'>
        <vendor id='${dev.vendor}'/>
        <product id='${dev.product}'/>
      </source>
    </hostdev>
  '';
  
  mkPciPassthrough = vm-name: vm: dev-index: dev-name: let dev = vm.pci."${dev-name}"; in ''
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='${toString dev.domain}' bus='${toString dev.bus}' slot='${toString dev.slot}' function='${toString dev.function}'/>
      </source>
    </hostdev>
  '';
  
  mkScsiPassthrough = vm-name: vm: dev-index: dev-name: let dev = vm.scsi."${dev-name}"; in 
    ''
      <hostdev mode='subsystem' type='scsi' managed='no' rawio='yes'>
        <source>
          <adapter name='scsi_host${toString dev.source.controller}'/>
          <address bus='${toString dev.source.bus}' target='${toString dev.source.target}' unit='${toString dev.source.unit}'/>
        </source>
        <address type="${dev.target.type}" ${optionalString (dev.target.controller != null) ''controller="${toString dev.target.controller}" ''}${optionalString (dev.target.bus != null) ''bus="${toString dev.target.bus}" ''}${optionalString (dev.target.unit != null) ''unit="${toString dev.target.unit}" ''}/>
      </hostdev>
    '';
    /*else throw ''
      Only scsi drive's can be passed through in this way for now. Anything else you can do via `vm.extra-config = "bla bla bla"`.
      '';*/
  
  /*
  
  <hostdev mode='subsystem' type='scsi' sgio='filtered' rawio='yes'>
    <source>
      <adapter name='scsi_host0'/>
      <address bus='0' target='0' unit='0'/>
    </source>
    <readonly/>
    <address type='drive' controller='0' bus='0' target='0' unit='0'/>
  </hostdev>
  */
  
  mkShare = vm-name: vm: mount-name: let 
    mount = vm.shares."${mount-name}";
    
    /*
    
      <driver type='virtiofs' queue='1024'/>
      <binary path='${pkgs.virtiofsd}/bin/virtiofsd' xattr='on'>
        <cache mode='always'/>
        <lock posix='on' flock='on'/>
      </binary>
    */
  in ''
    <filesystem type='mount' accessmode='mapped'>
      <source dir='${mount.source}'/>
      <target dir='${mount-name}'/>
    </filesystem>
  '';
  
  mkCreateDiskScript = vm-name: vm: disk-name: let disk = vm.disks."${disk-name}"; in if disk.dev != null then "" else
  ''
    echo "# managing volume 'vm-${vm-name}-${disk-name}'"
    export diskpath=$(virsh vol-path 'vm-${vm-name}-${disk-name}' --pool ${disk.pool} || echo "")
    if [ "$diskpath" == "" ]; then
      echo "# creating volume 'vm-${vm-name}-${disk-name}'"
      virsh vol-create-as ${disk.pool} 'vm-${vm-name}-${disk-name}' '${toString disk.size}${disk.size-unit}'
      export diskpath=$(virsh vol-path 'vm-${vm-name}-${disk-name}' --pool ${disk.pool})
      ${if disk.image != null then ''
        echo "# cloning image to '$diskpath'"
        qemu-img convert ${disk.image} "$diskpath"
      '' else ""}
    fi
  '';
  
  mkPoolScript = pool-name: let pool = cfg.pools.${pool-name}; in
  ''
    echo "# trying to create pool '${pool-name}'"
    virsh pool-define-as --name ${pool-name} --source-name ${pool.source} --type ${pool.type} || true
    ${if pool.start then ''
      echo "# trying to start pool '${pool-name}'"
      virsh pool-start ${pool-name} || true
    '' else ""}
  '';
  
  mkNetworkScript = net-name: let 
    net = cfg.networks.${net-name}; 
    xml = pkgs.writeText "libvirt-${net-name}.xml" ''
      <network  xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
        <name>${net-name}</name>
        <uuid></uuid>
        <bridge name="${net-name}"/>
        ${if net.nat != null then ''
          <forward mode="nat">
            <nat>
              <port start="${net.nat.start-port}" end="${net.nat.end-port}"/>
            </nat>
          </forward>
        '' else if net.routed != null then ''
          <forward mode="route" dev="${net.routed.dev}"/>
        '' else ""}
        <ip address="${net.host-address}" netmask="${net.netmask}">
          <dhcp>
            <range start="${net.dhcp-lowest}" end="${net.dhcp-highest}"/>
          </dhcp>
        </ip>
        <dnsmasq:options>
          ${""/* the guests should not simply know every dns entry in the host's /etc/hosts file... */}
          <dnsmasq:option value="no-hosts"/>
        </dnsmasq:options>
      </network>
    '';
  in mkDefineNetworkScript net-name xml net.start;
  
  mkDefineNetworkScript = net-name: xml: start: ''
    echo "# ======== managing network '${net-name}' ========="
    uuid="$(virsh net-uuid '${net-name}' || true)"
    # echo "# undefining network '${net-name}'"
    # virsh net-undefine '${net-name}' || true
    echo "# stopping network '${net-name}'"
    virsh net-destroy '${net-name}' || true
    echo "# (re-)defining network '${net-name}' [$uuid] (from ${xml})"
    # echo "virsh net-define <(sed \"s:<uuid></uuid>:<uuid>$uuid</uuid>:\" '${xml}')"
    virsh net-define <(sed "s:<uuid></uuid>:<uuid>$uuid</uuid>:" '${xml}')
    # virsh net-define '${xml}'
    ${optionalString start ''
      echo "# starting network '${net-name}'"
      virsh net-start '${net-name}' || true
    ''}
    echo "# ==== finished managing network '${net-name}' ===="
  '';
  
  
  mkUsbServices = vm-name: let
    vm = cfg.vms."${vm-name}";
    
    mkUsbService = dev-name: let
      dev = vm.usb."${dev-name}";
      
      xml = pkgs.writeText "virtm-usb-${dev.vendor}-${dev.product}.xml" ''<hostdev mode='subsystem' type='usb'><source><vendor id='${dev.vendor}'/><product id='${dev.product}'/></source></hostdev>'';
      
      doit = verb: {
        "virtm-usb-${verb}-${dev.vendor}-${dev.product}" = {
          enable = dev.hotplug;
          serviceConfig = {
            Type = "oneshot";
            RuntimeDirectory = "virtm-usb-${verb}-${dev.vendor}-${dev.product}";
          };
          script = ''
            set -xe
            ${pkgs.libvirt}/bin/virsh ${verb}-device ${vm-name} ${xml}
          '';
        };
      };
    in lib.mkMerge [
      (doit "attach")
      (doit "detach")
    ];
  in lib.mkMerge (map mkUsbService (attrNames vm.usb));
  
  
  mkUsbUdevRules = vm-name: let
    vm = cfg.vms."${vm-name}";
    
    mkUsbUdevRule = dev-name: let
      dev = vm.usb."${dev-name}";
    # in the remove rule the ATTRS are not filled, but the ENVs are filled. Also note, that SYSTEMD_WANTS only works for attaching (adding) devices, not for device removal. Thus we use `RUN+=systemctl start ...`
    in optionalString dev.hotplug ''
        SUBSYSTEM=="usb", ACTION=="add", ENV{PRODUCT}=="${lib.removePrefix "0" (lib.removePrefix "0" (lib.removePrefix "0" (builtins.substring 2 65535 dev.vendor)))}/${lib.removePrefix "0" (lib.removePrefix "0" (lib.removePrefix "0" (builtins.substring 2 65535 dev.product)))}/*", RUN+="${pkgs.systemd}/bin/systemctl start virtm-usb-attach-${dev.vendor}-${dev.product}.service"
        
        SUBSYSTEM=="usb", ACTION=="remove", ENV{PRODUCT}=="${lib.removePrefix "0" (lib.removePrefix "0" (lib.removePrefix "0" (builtins.substring 2 65535 dev.vendor)))}/${lib.removePrefix "0" (lib.removePrefix "0" (lib.removePrefix "0" (builtins.substring 2 65535 dev.product)))}/*", RUN+="${pkgs.systemd}/bin/systemctl start virtm-usb-detach-${dev.vendor}-${dev.product}.service"
      '';
  in concatStringsSep "\n" (map mkUsbUdevRule (attrNames vm.usb));
  
in
{

  options = {
    services = {
      virtm = {
        enable = mkEnableOption "virtm";
        nested = mkEnableOption "nested virtualisation";
        vms = mkOption {
          type = attrsOf (submodule (import ./vm.nix));
          default = {};
        };
        pools = mkOption {
          type = attrsOf (submodule (import ./pool.nix));
          default = {};
        };
        networks = mkOption {
          type = attrsOf (submodule (import ./net.nix));
          default = {};
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable) (lib.mkMerge [
  
    {
      
      boot.kernelModules = [ "kvm-amd" "kvm-intel" "8021q" "loop" "virtio" "9p" "9pnet" "9pnet_virtio" "vfio-pci" "vfio_virqfd" "vfio_iommu_type1" "vfio" ];
      # this is so that the nvidia driver does not take control of any nvidia graphics card
      boot.blacklistedKernelModules = ["nouveau"];
      boot.kernelParams = ["intel_iommu=on" (lib.mkIf cfg.nested "kvm_intel nested=1") (lib.mkIf cfg.nested "kvm_amd nested=1")];
      
      # this is needed for NAT and prolly also other stuff
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      
      #boot.kernel.sysctl."net.ipv4.conf.all.proxy_arp" = 1;
      #boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
      
      boot.kernel.sysctl."net.ipv4.conf.all.arp_filter" = 1;
      boot.kernel.sysctl."net.ipv4.conf.all.arp_ignore" = 1;
      boot.kernel.sysctl."net.ipv4.conf.all.arp_announce" = 2;
      
      /*
      nixpkgs.overlays = [(self: super: 
        super.libvirtd.overrideAttrs (old: {
          
        });
      )];
      */
      # they seem to have forgotten that...
      systemd.services = lib.mkMerge [
        (lib.mkMerge (map mkUsbServices (attrNames cfg.vms))) 
        
        {
          libvirtd.path = lib.mkAfter [pkgs.zfs];
          virtm = {
            after = [ "libvirtd.service" "zfs-import.target" "network-setup.service"];
            requires = [ "libvirtd.service" "zfs-import.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = "yes";
            };
            path = with pkgs; [libvirt qemu iproute2 zfs];
            script = ''
              set -x
              ${concatStringsSep "\n" (map mkPoolScript (attrNames cfg.pools))}

              ${concatStringsSep "\n" (map mkNetworkScript (attrNames cfg.networks))}
            '';
          };
          virtm-autostart = {
            requires = [ "libvirtd.service" "zfs-import.target" ];
            wantedBy = lib.mkDefault [ "multi-user.target" ];
            serviceConfig = {
              Type = "forking";
              RemainAfterExit = "no";
              ExecStart = "${pkgs.writeScriptBin "virtm-autostart.sh" 
              ''#!/bin/sh
                ${pkgs.coreutils}/bin/echo "autostarting vms"
                set -x
                ${concatStringsSep "\n" (map (vm-name: let vm = cfg.vms.${vm-name}; in optionalString (vm.start) ''${pkgs.coreutils}/bin/sleep ${toString vm.start-delay}s && ${pkgs.systemd}/bin/systemctl start vmm-${vm-name} && ${pkgs.libvirt}/bin/virsh start ${vm-name} || true &'') (attrNames cfg.vms))}
              ''}/bin/virtm-autostart.sh";
              /*
              ExecStop = "${pkgs.writeScriptBin "stop.sh" 
              ''#!/bin/sh
                ${pkgs.coreutils}/bin/echo "stopping vms"
                set -x
                ${concatStringsSep "\n" (map (vm-name: let vm = cfg.vms.${vm-name}; in optionalString vm.start ''${pkgs.systemd}/bin/systemctl stop vm-${vm-name}'') (attrNames cfg.vms))}
              ''}/bin/stop.sh";
              */
            };
          };
        }
      ];
      
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          ovmf.enable = true;
          runAsRoot = false;
        };
        onBoot = "ignore";
        onShutdown = "shutdown";
      };
      
      
      services.udev.extraRules = concatStringsSep "\n" (map mkUsbUdevRules (attrNames cfg.vms));
      
    }
      

    {
      
      # networking.interfaces = lib.mkMerge (lib.imap1 mkHostOnlyInterfaces (attrNames cfg.vms));
      
      systemd.services = lib.mkMerge (
        lib.imap1 (vm-index: vm-name: let 
          vm = cfg.vms.${vm-name};
          timeout = vm.timeout;
        in
        {
          # starting of vms is handled via `virsh start` and virtm-autostart (which starts with a configured delay the machines that have `start = true`)
          /*
          "vm-${vm-name}" = {
            after = [ "vmm-${vm-name}.service" ];
            
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = "yes";
            };
            path = with pkgs; [libvirt qemu iproute2 zfs];
            script = ''
              echo "trying to start vm"
              virsh start '${vm-name}' || true
            '';
            preStop =
              ''
                virsh shutdown '${vm-name}' || true
                let "timeout = $(date +%s) + ${toString timeout}"
                while [ "$(virsh list --name | grep --count '^${vm-name}$')" -gt "0" ]; do
                  if [ "$(date +%s)" -ge "$timeout" ]; then
                    virsh destroy '${vm-name}' || true
                  else
                    # The machine is still running, let's give it some time to shut down
                    sleep 1.0
                  fi
                done
                ${concatStringsSep "\n" (imap1 (stopVmOwnedNetwork vm-index vm-name vm) (vm.networking))}
              '';
          };
          */
          "vmm-${vm-name}" = {
            after = [ "virtm.service" "network-setup.service" ];
            before = [ "vm-${vm-name}.service" ];
            requisite = [ "virtm.service" ];
            wantedBy = lib.mkDefault [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = "yes";
            };
            path = with pkgs; [libvirt qemu iproute2 zfs];
            restartIfChanged = true;
            script =
              let
              #         <nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.fd'></nvram>
                xml = pkgs.writeText "libvirt-vm-${vm-name}.xml"
                  ''
                    <domain type="kvm">
                      <name>${vm-name}</name>
                      <uuid></uuid>
                      <os>
                        <type arch='x86_64' machine='pc'>hvm</type>
                        ${if vm.efi then ''
                          <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
                        '' else ''
                          <smbios mode='emulate'/>
                        ''}
                        <bootmenu enable='yes' timeout='3000'/>
                        <boot dev='cdrom'/>
                        <boot dev='hd'/>
                      </os>
                      ${optionalString 
                          vm.nested 
                          # this might have the effect, that porting the VM to another host triggers a different system recognition (which would require OS reactivation in windows for example)
                          ''
                            <cpu mode='host-model' check='partial' />
                          ''}
                      <memoryBacking>
                        <source type='memfd'/>
                        <access mode='shared'/>
                      </memoryBacking>
                      <memory unit="${vm.memory-size-unit}">${toString vm.memory}</memory>
                      <devices>
                        <controller type='ide' index='0'>
                          <alias name='ide'/>
                          <address type='pci' domain='0x0000' bus='0x00' slot='0x1' function='0x1'/>
                        </controller>
                        ${# UHCI = USB 1.1, EHCI = USB 2.0, XHCI = USB 3.0... apparently XHCI seems to be the only backwards compatible choice... remember that this is important to get burners to run....
                        ""}
                        <controller type='usb' index='0' model='qemu-xhci'>
                          <alias name='usb'/>
                          <address type='pci' domain='0x0000' bus='0x00' slot='0x1' function='0x2'/>
                        </controller>
                        <hub type='usb'/>
                        <hub type='usb'/>
                        <controller type='scsi' index='0' model='virtio-scsi'>
                          <address type='pci' domain='0x0000' bus='0x03' slot='0x1' function='0x0'/>
                        </controller>

                        ${concatStringsSep "\n" (imap1 (mkInterface2 vm-index vm-name vm) (vm.networking))}
                        ${concatStringsSep "\n" (map (mkDisk vm-name vm) (attrNames vm.disks))}
                        ${concatStringsSep "\n" (imap1 (mkCd vm-name vm) (attrNames vm.cds))}
                        ${concatStringsSep "\n" (imap1 (mkUsbPassthrough vm-name vm) (attrNames vm.usb))}
                        ${concatStringsSep "\n" (imap1 (mkPciPassthrough vm-name vm) (attrNames vm.pci))}
                        ${concatStringsSep "\n" (imap1 (mkScsiPassthrough vm-name vm) (attrNames vm.scsi))}
                        
                        ${concatStringsSep "\n" (map (mkShare vm-name vm) (attrNames vm.shares))}
                        ${if vm.vnc != null && vm.vnc.enable then ''
                          <graphics type="vnc" ${if vm.vnc.port != null then '' port="${toString vm.vnc.port}"'' else ''autoport="yes"''} ${if vm.vnc.address != null then '' listen="${vm.vnc.address}"'' else ''''} ${if vm.vnc.address != null then '' passwd="${vm.vnc.password}"'' else ''''} ${optionalString (vm.vnc.keymap != null) '' keymap="${vm.vnc.keymap}"''}/>
                        '' else 
                        # we never add... <graphics type="spice" autoport="yes"/>
                        ''
                          
                        ''}
                        ${optionalString (vm.egl-headless != null) ''
                          <graphics type='egl-headless'>
                            <gl rendernode="${vm.egl-headless}"/>
                          </graphics>
                        ''}    
                        <input type="keyboard" bus="usb"/>
                        ${"" /* this don't work properly
                        <console type='pty'>
                          <target type='serial'/>
                        </console>
                        */}
                        <channel type='unix'>
                           <source mode='bind'/>
                           <target type='virtio' name='org.qemu.guest_agent.0'/>
                        </channel>
                        ${concatStringsSep "\n" vm.extra-devices}
                      </devices>
                      <features>
                        <acpi/>
                        ${concatStringsSep "\n" vm.extra-features}
                      </features>
                      ${concatStringsSep "\n" vm.extra-config}
                    </domain>
                  '';
                  /*
                        <video>
                          <model type='virtio' vram='16384' heads='1'>
                            <acceleration accel3d='yes'/>
                          </model>
                          <driver name='qemu'/>
                        </video>
                  */
              in
                # 
                ''
                  set -x
                  echo "# ======== managing vm '${vm-name}' ========="
                  echo "# managing disks"
                  ${concatStringsSep "\n" (map (mkCreateDiskScript vm-name vm) (attrNames vm.disks))}
                  
                  echo "# managing host-only networks"
                  ${concatStringsSep "\n" (imap1 (mkVmOwnedNetwork vm-index vm-name vm) (vm.networking))}
                  
                
                  uuid="$(virsh domuuid '${vm-name}' || true)"
                  echo "# (re-)defining vm"
                  echo "virsh define <(sed \"s:<uuid></uuid>:<uuid>$uuid</uuid>:\" '${xml}')"
                  virsh define <(sed "s:<uuid></uuid>:<uuid>$uuid</uuid>:" '${xml}')
                  
                  
                '';
          };
        }) (attrNames cfg.vms)
      );
    }
  ]);
}

