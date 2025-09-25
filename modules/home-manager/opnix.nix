# /modules/home-manager/opnix.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Import the Opnix Home Manager module.
    inputs.opnix.homeManagerModules.default
  ];

  # Enable the 1Password secrets management program.
  programs.onepassword-secrets = {
    enable = true;
    tokenFile = "${config.home.homeDirectory}/.config/op/opnix-token";
    # Define secrets to be provisioned at runtime.
    secrets = {
      "sshKey" = {
        path = ".ssh/id_ed25519";
        # Format: op://<vault>/<item>/<field>
        reference = "op://Private/SSH Key/private key";
        # Set appropriate file permissions.
        mode = "0600";
      };
      "serviceAccountToken" = {
        path = ".config/op/service-account-token";
        # Reference the service account token stored in your vault
        reference = "op://Private/Service Account Token/credential";
        mode = "0600";
      };
      # Add more secrets as needed
    };
  };

  # Ensure directories exist before secrets are written.
  home.activation.ensureOnePasswordDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.ssh"
    chmod 700 "${config.home.homeDirectory}/.ssh"
    mkdir -p "${config.home.homeDirectory}/.config/op"
    chmod 700 "${config.home.homeDirectory}/.config/op"
  '';

  # Configure the SSH client to use the 1Password SSH agent for authentication.
  # This requires enabling the SSH agent in the 1Password desktop app settings.
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        IdentityAgent ~/.1password/agent.sock
    '';
  };

  # Setup Git with 1Password
  programs.git = {
    enable = true;
    # Note: userName and userEmail should be configured in user-specific files
    # userName = "Your Name";
    # userEmail = "your.email@example.com";
    signing = {
      # Note: Configure your SSH signing key in user-specific configuration
      # key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourPublicKeyHere";
      signByDefault = true;
      # Use SSH key from 1Password for signing
    };
    extraConfig = {
      gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
      gpg.format = "ssh";
    };
  };

  # Configure shell environment for 1Password service account
  home.sessionVariables = {
    # This will be set after the service account token is provisioned
    OP_SERVICE_ACCOUNT_TOKEN = "$(cat ~/.config/op/service-account-token 2>/dev/null || echo '')";
  };

  # Ensure the 1Password CLI is available
  home.packages = with pkgs; [
    _1password-cli
  ];
}