# Minimal Disko layout for CLI usage
# This file is a function so you can pass the disk device at runtime.
# Example:
#   nix run --extra-experimental-features 'nix-command flakes' \
#     github:nix-community/disko -- --mode disko \
#     --argstr device /dev/disk/by-id/<YOUR-DISK-ID> \
#     ./disko-layout.nix
{ device ? "/dev/disk/by-id/REPLACE_WITH_YOUR_DISK_ID", ... }:
{
	disko.devices = {
		disk = {
			main = {
				device = device;
				type = "disk";
				content = {
					type = "gpt";
					partitions = {
						ESP = {
							size = "1G";
							type = "EF00";
							content = {
								type = "filesystem";
								format = "vfat";
								mountpoint = "/boot";
							};
						};
						swap = {
							size = "8G";
							content = {
								type = "swap";
								randomEncryption = true;
							};
						};
						luks = {
							size = "100%";
							content = {
								type = "luks";
								name = "cryptroot";
								settings = {
									allowDiscards = true;
								};
								content = {
									type = "zfs";
									pool = "rpool";
								};
							};
						};
					};
				};
			};
		};
		zpool = {
			rpool = {
				type = "zpool";
				options = {
					ashift = "12";
					autotrim = "on";
				};
				rootFsOptions = {
					compression = "zstd";
					acltype = "posixacl";
					xattr = "sa";
					relatime = "on";
					mountpoint = "none";
				};
				datasets = {
					"local/root" = {
						type = "zfs_fs";
						mountpoint = "/";
						postCreateHook = ''
							zfs snapshot rpool/local/root@blank
						'';
					};
					"local/nix" = {
						type = "zfs_fs";
						mountpoint = "/nix";
						options."com.sun:auto-snapshot" = "false";
					};
					"safe/persist" = {
						type = "zfs_fs";
						mountpoint = "/persist";
					};
					"safe/home" = {
						type = "zfs_fs";
						mountpoint = "/home";
					};
				};
			};
		};
	};
}
