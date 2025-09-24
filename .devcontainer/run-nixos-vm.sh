#!/usr/bin/env bash
set -euo pipefail

# Settings
VM_DISK="nixos-test.img"
VM_DISK_SIZE="8G"  # Small disk for testing
VM_RAM="4096"      # 4GB RAM
VM_CPUS="2"

# Paths
NIXOS_FLAKE="/workspaces/nixos"
DISKO_LAYOUT="/workspaces/nixos/disko-layout.nix"

# Create disk if not exists
if [ ! -f "$VM_DISK" ]; then
  echo "Creating virtual disk: $VM_DISK ($VM_DISK_SIZE)"
  qemu-img create -f qcow2 "$VM_DISK" "$VM_DISK_SIZE"
fi

# Launch QEMU VM
qemu-system-x86_64 \
  -enable-kvm \
  -m "$VM_RAM" \
  -smp "$VM_CPUS" \
  -drive file="$VM_DISK",format=qcow2,if=virtio \
  -cdrom "$NIXOS_FLAKE/result/iso/nixos.iso" \
  -boot d \
  -nographic \
  -serial mon:stdio \
  -net nic -net user,hostfwd=tcp::2222-:22 \
  -device virtio-rng-pci \
  -no-reboot

# Usage:
# 1. Build the NixOS ISO with your flake and disko config:
#    nix build .#nixosConfigurations.<hostname>.config.system.build.isoImage
# 2. Run this script to boot the VM and test install.
# 3. SSH into the VM: ssh -p 2222 nixos@localhost
# 4. Reboot the VM to test impermanence and persistence.
