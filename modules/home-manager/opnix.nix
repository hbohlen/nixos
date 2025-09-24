# /modules/home-manager/opnix.nix
{ pkgs, lib, inputs, ... }:

{
  imports = [
    # Import the Opnix Home Manager module.
    inputs.opnix.homeManagerModules.default
  ];

  # Enable the 1Password secrets management program.
  programs.onepassword-secrets = {
    enable = true;
    # Define secrets to be provisioned at runtime.
    secrets = {
      "sshKey" = {
        path = ".ssh/id_ed25519";
        # Format: op://<vault>/<item>/<field>
        reference = "op://hbohlen/SSH Private Key/private key";
        # Set appropriate file permissions.
        mode = "0600";
      };
      "serviceAccountToken" = {
        path = ".config/op/service-account-token";
        # Reference the service account token stored in your vault
        reference = "op://hbohlen/Service Account Token/credential";
        mode = "0600";
      };
      # Add more secrets as needed
    };
  };

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
    userName = "Hayden Bohlen";
    userEmail = "bohlenhayden@gmail.com";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1..."; # Replace with your SSH key from 1Password
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