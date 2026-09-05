# Hand-written, not nixos-generate-config output - there was no NixOS system
# to generate it from before the nixos-anywhere install. Standard boilerplate
# for a plain KVM/virtio guest (confirmed via `lsblk`: single virtio disk).
#
# fileSystems."/" is NOT declared here - disko.nix supplies it from the
# partition layout (disko.devices.disk.main.content.partitions.root.content).
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "virtio_pci" "virtio_scsi" "virtio_blk" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
