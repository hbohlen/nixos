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

```bash
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