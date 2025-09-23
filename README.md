# NixOS Configuration

Find your target disk id (recommended):

```
ls -l /dev/disk/by-id/
```

Run Disko, passing the disk by-id value (safer than /dev/nvme0n1):

```
sudo nix run --extra-experimental-features 'nix-command flakes' \
  github:nix-community/disko -- --mode disko \
  --argstr device /dev/disk/by-id/nvme-CT2000P310SSD8_24514D0F486C \
  ./disko-layout.nix
```

`nixos-install --flake .#desktop`

## Troubleshooting

- Bootloader install failed: If you see an error like `bootctl --esp-path=/boot install` failed, ensure the EFI System Partition (ESP) exists, is formatted as vfat, and mounted at `/boot` during install. With this repo, Disko creates and mounts the ESP at `/boot`. If you ran Disko without specifying the correct device, re-run with the proper `--argstr device /dev/disk/by-id/<id>`.
- Wrong device path: Avoid `/dev/nvme0n1` short names; prefer stable `/dev/disk/by-id/<id>` paths to prevent surprises when device enumeration changes.

### Fix: `efiSysMountPoint = '/boot' is not a mounted partition`

This means the ESP was not mounted at `/mnt/boot` when `nixos-install` tried to install systemd-boot.

1) Re-run Disko to ensure partitions are created and mounted (replace the device):

```bash
sudo nix run --extra-experimental-features 'nix-command flakes' \
  github:nix-community/disko -- --mode disko \
  --argstr device /dev/disk/by-id/nvme-WDS100T3X0C-00SJG0_190670800068 \
  ./disko-layout.nix

```

2) If you have already partitioned the disk, just mount everything:

```bash
sudo nix run --extra-experimental-features 'nix-command flakes' \
  github:nix-community/disko -- --mode mount \
  --argstr device /dev/disk/by-id/nvme-WDS100T3X0C-00SJG0_190670800068 \
  ./disko-layout.nix
```

3) Verify mounts (you should see `/mnt/boot`):

NixOS Root on ZFS

Customization

Unless stated otherwise, it is not recommended to customize system configuration before reboot.

UEFI support only

Only UEFI is supported by this guide. Make sure your computer is booted in UEFI mode.
Preparation

    Download NixOS Live Image and boot from it.

    sha256sum -c ./nixos-*.sha256

    dd if=input-file of=output-file bs=1M

    Connect to the Internet.

    Set root password or /root/.ssh/authorized_keys.

    Start SSH server

    systemctl restart sshd

    Connect from another computer

    ssh root@192.168.1.91

    Target disk

    List available disks with

    find /dev/disk/by-id/

    If virtio is used as disk bus, power off the VM and set serial numbers for disk. For QEMU, use -drive format=raw,file=disk2.img,serial=AaBb. For libvirt, edit domain XML. See this page for examples.

    Declare disk array

    DISK='/dev/disk/by-id/ata-FOO /dev/disk/by-id/nvme-BAR'

    For single disk installation, use

    DISK='/dev/disk/by-id/disk1'

    Set a mount point

    MNT=$(mktemp -d)

    Set partition size:

    Set swap size in GB, set to 1 if you don’t want swap to take up too much space

    SWAPSIZE=4

    Set how much space should be left at the end of the disk, minimum 1GB

    RESERVE=1

System Installation

    Partition the disks.

    Note: you must clear all existing partition tables and data structures from target disks.

    For flash-based storage, this can be done by the blkdiscard command below:

    partition_disk () {
     local disk="${1}"
     blkdiscard -f "${disk}" || true

     parted --script --align=optimal  "${disk}" -- \
     mklabel gpt \
     mkpart EFI 1MiB 4GiB \
     mkpart rpool 4GiB -$((SWAPSIZE + RESERVE))GiB \
     mkpart swap  -$((SWAPSIZE + RESERVE))GiB -"${RESERVE}"GiB \
     set 1 esp on \

     partprobe "${disk}"
    }

    for i in ${DISK}; do
       partition_disk "${i}"
    done

    Setup temporary encrypted swap for this installation only. This is useful if the available memory is small:

    for i in ${DISK}; do
       cryptsetup open --type plain --key-file /dev/random "${i}"-part3 "${i##*/}"-part3
       mkswap /dev/mapper/"${i##*/}"-part3
       swapon /dev/mapper/"${i##*/}"-part3
    done

    LUKS only: Setup encrypted LUKS container for root pool:

    for i in ${DISK}; do
       # see PASSPHRASE PROCESSING section in cryptsetup(8)
       printf "YOUR_PASSWD" | cryptsetup luksFormat --type luks2 "${i}"-part2 -
       printf "YOUR_PASSWD" | cryptsetup luksOpen "${i}"-part2 luks-rpool-"${i##*/}"-part2 -
    done

    Create root pool

        Unencrypted

        # shellcheck disable=SC2046
        zpool create \
            -o ashift=12 \
            -o autotrim=on \
            -R "${MNT}" \
            -O acltype=posixacl \
            -O canmount=off \
            -O dnodesize=auto \
            -O normalization=formD \
            -O relatime=on \
            -O xattr=sa \
            -O mountpoint=none \
            rpool \
            mirror \
           $(for i in ${DISK}; do
              printf '%s ' "${i}-part2";
             done)

        LUKS encrypted

        # shellcheck disable=SC2046
        zpool create \
            -o ashift=12 \
            -o autotrim=on \
            -R "${MNT}" \
            -O acltype=posixacl \
            -O canmount=off \
            -O dnodesize=auto \
            -O normalization=formD \
            -O relatime=on \
            -O xattr=sa \
            -O mountpoint=none \
            rpool \
            mirror \
           $(for i in ${DISK}; do
              printf '/dev/mapper/luks-rpool-%s ' "${i##*/}-part2";
             done)

    If not using a multi-disk setup, remove mirror.

    Create root system container:

        zfs create -o canmount=noauto -o mountpoint=legacy rpool/root

    Create system datasets, manage mountpoints with mountpoint=legacy

    zfs create -o mountpoint=legacy rpool/home
    mount -o X-mount.mkdir -t zfs rpool/root "${MNT}"
    mount -o X-mount.mkdir -t zfs rpool/home "${MNT}"/home

    Format and mount ESP. Only one of them is used as /boot, you need to set up mirroring afterwards

    for i in ${DISK}; do
     mkfs.vfat -n EFI "${i}"-part1
    done

    for i in ${DISK}; do
     mount -t vfat -o fmask=0077,dmask=0077,iocharset=iso8859-1,X-mount.mkdir "${i}"-part1 "${MNT}"/boot
     break
    done

System Configuration

    Generate system configuration:

    nixos-generate-config --root "${MNT}"

    Edit system configuration:

    nano "${MNT}"/etc/nixos/hardware-configuration.nix

    Set networking.hostId:

    networking.hostId = "abcd1234";

    If using LUKS, add the output from following command to system configuration

    tee <<EOF
      boot.initrd.luks.devices = {
    EOF

    for i in ${DISK}; do echo \"luks-rpool-"${i##*/}-part2"\".device = \"${i}-part2\"\; ; done

    tee <<EOF
    };
    EOF

    Install system and apply configuration

    nixos-install  --root "${MNT}"

    Wait for the root password reset prompt to appear.

    Unmount filesystems

    cd /
    umount -Rl "${MNT}"
    zpool export -a

    Reboot

    reboot

    Set up networking, desktop and swap.

    Mount other EFI system partitions then set up a service for syncing their contents.


findmnt -R /mnt | grep -E '/mnt$|/mnt/(boot|nix|persist|home)'
```

4) If `/mnt/boot` is still missing, mount ESP manually (careful: format only if needed):

```bash
# Identify the ESP by GPT partlabel created by Disko
ls -l /dev/disk/by-partlabel/disk-main-ESP

# If not formatted (only do this on the correct ESP; data loss otherwise)
# sudo mkfs.vfat -F32 -n ESP /dev/disk/by-partlabel/disk-main-ESP

# Mount ESP at the target root
sudo mkdir -p /mnt/boot
sudo mount -o umask=0077 /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
```

5) Re-run the install:

```bash
sudo nixos-install --flake .#desktop
```

If you see a warning about `/boot/loader/random-seed` being world-accessible, ensure `/boot` is mounted with a restrictive umask. The Disko layout now sets `umask=0077` automatically. If needed during a manual session:

```bash
sudo mount -o remount,umask=0077 /mnt/boot
```

A modern, declarative, and ephemeral NixOS system with ZFS, Impermanence, and Hyprland.

## Architecture Overview

This is a modern, declarative NixOS system built on the "Erase Your Darlings" philosophy. The architecture combines:

- **Nix Flakes**: For reproducible, hermetic system definition
- **Disko**: For declarative partitioning
- **ZFS with LUKS encryption**: For advanced filesystem features
- **Impermanence**: For ephemeral root filesystem
- **Hyprland**: Wayland compositor for a modern desktop experience
- **Opnix**: For runtime secret injection via 1Password

## Project Structure

- `flake.nix`: Central entry point for all configuration
- `hosts/`: Machine-specific configurations
  - `laptop/`: Laptop-specific settings
  - `desktop/`: Desktop-specific settings
  - `server/`: Server-specific settings
- `modules/`: Reusable modules
  - `nixos/`: System-level modules
    - `common.nix`: Shared system configurations
    - `disko-zfs.nix`: Disk partitioning and ZFS setup
    - `impermanence.nix`: Ephemeral root configuration
  - `home-manager/`: User-level modules
    - `desktop.nix`: Hyprland and desktop applications
    - `opnix.nix`: Secret management
- `users/`: User accounts and Home Manager configurations
- `secrets/`: Placeholder for encrypted secrets
- `scripts/`: Helper scripts for system management

## Build Commands

- **Full system rebuild**: `./scripts/rebuild.sh` (auto-detects hostname)
- **Manual rebuild**: `sudo nixos-rebuild switch --flake .#hostname`
- **Test build**: `nixos-rebuild build --flake .#hostname`
- **Dry run**: `nixos-rebuild dry-activate --flake .#hostname`
- **Check configuration**: `nix flake check`

## Getting Started

1. Clone this repository
2. Customize `hosts/laptop/hardware-configuration.nix` for your hardware
3. Provision the disk with Disko using your by-id path (see above)
4. Set your username and preferences in the `users` directory
5. Build or install: `nixos-rebuild build --flake .#desktop` or `sudo nixos-install --flake .#desktop`

## Key Features

- **Declarative System**: Everything from disk partitioning to application themes is defined as code
- **Ephemeral Root**: The root filesystem is reset to a pristine state on each boot
- **Persistent State**: Specific files and directories can be opted into persistence
- **Modern Desktop**: Hyprland Wayland compositor with a cohesive theme
- **Secret Management**: 1Password integration for secure runtime secret injection

## Customization

- Add new host configurations in the `hosts/` directory
- Create additional user configurations in the `users/` directory
- Extend functionality with new modules in the `modules/` directory
- Adjust the disk layout in `modules/nixos/disko-zfs.nix`
- Modify persistence rules in `modules/nixos/impermanence.nix`

## References

- [NixOS Documentation](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Disko](https://github.com/nix-community/disko)
- [Impermanence](https://github.com/nix-community/impermanence)
- [Hyprland](https://hyprland.org/)
- [Opnix](https://github.com/brizzbuzz/opnix)