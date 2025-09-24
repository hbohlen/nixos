FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install QEMU, KVM, Nix, and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      qemu-system-x86 \
      qemu-utils \
      libvirt-clients \
      libvirt-daemon-system \
      virtinst \
      bridge-utils \
      ovmf \
      sudo \
      git \
      curl \
      wget \
      kmod \
      lvm2 \
      zfsutils-linux \
      parted \
      xz-utils \
      vim \
      less \
      openssh-client \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Nix
RUN adduser --disabled-password --gecos '' nixuser && \
    su nixuser -c "sh <(curl -L https://nixos.org/nix/install) --no-daemon"

ENV USER=nixuser
ENV HOME=/home/nixuser
ENV PATH="/home/nixuser/.nix-profile/bin:/home/nixuser/.nix-profile/sbin:/home/nixuser/.nix-profile/libexec:/home/nixuser/.nix-profile/libexec:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Enable KVM permissions
RUN usermod -aG kvm nixuser

USER nixuser
WORKDIR /workspaces/nixos

# Optional: install Nix Flakes support
RUN . /home/nixuser/.nix-profile/etc/profile.d/nix.sh && \
    nix --extra-experimental-features 'nix-command flakes' flake show || true

CMD ["bash"]
