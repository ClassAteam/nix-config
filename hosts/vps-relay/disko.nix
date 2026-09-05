# Declarative partition layout for nixos-anywhere/disko.
# Matches the live disk on the Fornex VPS: a single virtio disk, /dev/vda,
# 20G, BIOS boot (no UEFI) - confirmed via `lsblk` and `ls /sys/firmware/efi`
# on the stock Ubuntu image before wiping it.
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # BIOS + GPT needs a small unformatted partition for GRUB's core.img,
            # since there's no ESP to hold it (this box has no UEFI).
            boot = {
              size = "1M";
              type = "EF02"; # BIOS boot partition
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
