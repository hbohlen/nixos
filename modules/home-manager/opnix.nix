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
      "ssh-key" = {
        path = ".ssh/id_ed25519";
        # Format: op://<vault>/<item>/<field>
        reference = "op://Personal/SSH Private Key/private key";
        # Set appropriate file permissions.
        mode = "0600";
      };
      "api-token" = {
        path = ".config/my-app/api.token";
        reference = "op://Work/API Tokens/My App Token";
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
    userName = "Your Name";
    userEmail = "your.email@example.com";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1..."; # Replace with your SSH key
      signByDefault = true;
      # Use SSH key from 1Password for signing
    };
    extraConfig = {
      gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
      gpg.format = "ssh";
    };
  };
}