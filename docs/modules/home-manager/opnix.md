# opnix.nix - 1Password Secret Management Integration

**Location:** `modules/home-manager/opnix.nix`

## Purpose

Provides secure secret management integration using 1Password through the Opnix Home Manager module. Enables automatic provisioning of secrets like SSH keys, API tokens, and configuration files at runtime without storing them in the Nix configuration.

## Dependencies

- **External Flakes:** `inputs.opnix.homeManagerModules.default`
- **System Requirements:** 1Password CLI, 1Password desktop app (for SSH agent)
- **Integration:** Works with system-level 1Password configuration

## Features

### 1Password Secrets Management

#### Core Secret Provisioning
```nix
programs.onepassword-secrets = {
  enable = true;
  tokenFile = "${config.home.homeDirectory}/.config/op/opnix-token";
  
  secrets = {
    "sshKey" = {
      path = ".ssh/id_ed25519";
      reference = "op://Private/SSH Key/private key";
      mode = "0600";
    };
    
    "serviceAccountToken" = {
      path = ".config/op/service-account-token";
      reference = "op://Private/Service Account Token/credential";
      mode = "0600";
    };
  };
};
```

#### Secret Reference Format
Secrets are referenced using 1Password's URI format:
```
op://<vault>/<item>/<field>
```

Examples:
- `op://Private/SSH Key/private key` - SSH private key
- `op://Work/API Keys/github-token` - GitHub API token  
- `op://Personal/Database/password` - Database password

### SSH Integration

#### SSH Key Management
```nix
programs.ssh = {
  enable = true;
  extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
};
```

This configuration:
- Uses 1Password SSH agent for authentication
- Automatically loads SSH keys from 1Password
- Provides seamless SSH key management across devices

### Git Integration

#### Signed Commits with 1Password
```nix
programs.git = {
  enable = true;
  userName = "Hayden Bohlen";
  userEmail = "bohlenhayden@gmail.com";
  
  signing = {
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqnk8Q2ZJ4KkHhT7gQJ8vX9zY2WxLmNpOqRtUvWxY";
    signByDefault = true;
  };
  
  extraConfig = {
    gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
    gpg.format = "ssh";
  };
};
```

### Environment Variable Integration

#### Service Account Configuration
```nix
home.sessionVariables = {
  OP_SERVICE_ACCOUNT_TOKEN = "$(cat ~/.config/op/service-account-token 2>/dev/null || echo '')";
};
```

### Directory Preparation

#### Secure Directory Creation
```nix
home.activation.ensureOnePasswordDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  mkdir -p "${config.home.homeDirectory}/.ssh"
  chmod 700 "${config.home.homeDirectory}/.ssh"
  mkdir -p "${config.home.homeDirectory}/.config/op"
  chmod 700 "${config.home.homeDirectory}/.config/op"
'';
```

## Usage Examples

### Basic Secret Management Setup
```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/opnix.nix
  ];
  
  # Basic configuration automatically provisions SSH keys and service account
}
```

### Extended Secret Configuration
```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/opnix.nix
  ];
  
  # Add additional secrets
  programs.onepassword-secrets.secrets = {
    # Development secrets
    "githubToken" = {
      path = ".config/gh/token";
      reference = "op://Development/GitHub/personal-access-token";
      mode = "0600";
    };
    
    "dockerConfig" = {
      path = ".docker/config.json";
      reference = "op://Development/Docker/config";
      mode = "0600";
    };
    
    # Cloud credentials
    "awsCredentials" = {
      path = ".aws/credentials";
      reference = "op://Cloud/AWS/credentials-file";
      mode = "0600";
    };
    
    "gcpServiceAccount" = {
      path = ".config/gcloud/service-account.json";
      reference = "op://Cloud/GCP/service-account-key";
      mode = "0600";
    };
    
    # Database credentials
    "pgpass" = {
      path = ".pgpass";
      reference = "op://Databases/PostgreSQL/pgpass-file";
      mode = "0600";
    };
  };
}
```

### Development Workflow Integration
```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/opnix.nix
  ];
  
  # Development-specific secret management
  programs.onepassword-secrets.secrets = {
    # API tokens for development tools
    "npmrc" = {
      path = ".npmrc";
      reference = "op://Development/NPM/npmrc-config";
      mode = "0600";
    };
    
    "pypirc" = {
      path = ".pypirc";
      reference = "op://Development/PyPI/pypirc-config";
      mode = "0600";
    };
    
    "cargoCredentials" = {
      path = ".cargo/credentials.toml";
      reference = "op://Development/Cargo/credentials";
      mode = "0600";
    };
    
    # IDE configurations with sensitive data
    "vscodeSettings" = {
      path = ".vscode/settings-secret.json";
      reference = "op://Development/VSCode/secret-settings";
      mode = "0600";
    };
  };
  
  # Git configuration with signing
  programs.git.extraConfig = {
    # Use 1Password for commit signing
    user.signingkey = "$(op read 'op://Development/SSH Key/public key')";
    
    # Additional Git configuration
    credential.helper = "!op-git-credential-helper";
  };
}
```

### Multi-Environment Configuration
```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/opnix.nix
  ];
  
  # Environment-specific secrets
  programs.onepassword-secrets.secrets = {
    # Production environment
    "prodEnv" = {
      path = ".config/environments/production.env";
      reference = "op://Production/Environment/variables";
      mode = "0600";
    };
    
    # Staging environment
    "stagingEnv" = {
      path = ".config/environments/staging.env";
      reference = "op://Staging/Environment/variables";
      mode = "0600";
    };
    
    # Development environment
    "devEnv" = {
      path = ".config/environments/development.env";
      reference = "op://Development/Environment/variables";
      mode = "0600";
    };
    
    # Kubernetes configurations
    "kubeconfig" = {
      path = ".kube/config";
      reference = "op://Infrastructure/Kubernetes/kubeconfig";
      mode = "0600";
    };
  };
}
```

## Advanced Configuration

### Custom Service Account Setup
```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/opnix.nix
  ];
  
  # Custom service account configuration
  programs.onepassword-secrets = {
    tokenFile = "${config.home.homeDirectory}/.config/op/custom-token";
    
    secrets = {
      # Use custom service account for specific secrets
      "enterpriseSSH" = {
        path = ".ssh/enterprise_key";
        reference = "op://Enterprise/SSH Keys/production-key";
        mode = "0600";
      };
    };
  };
  
  # Multiple service account tokens
  home.activation.setupMultipleTokens = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Setup multiple service account tokens for different contexts
    mkdir -p "${config.home.homeDirectory}/.config/op/contexts"
    chmod 700 "${config.home.homeDirectory}/.config/op/contexts"
  '';
  
  # Environment-specific configurations
  home.sessionVariables = {
    OP_PERSONAL_TOKEN = "$(cat ~/.config/op/personal-token 2>/dev/null || echo '')";
    OP_WORK_TOKEN = "$(cat ~/.config/op/work-token 2>/dev/null || echo '')";
  };
}
```

### SSH Agent Configuration
```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/opnix.nix
  ];
  
  # Advanced SSH configuration
  programs.ssh = {
    enable = true;
    
    # 1Password SSH agent configuration
    extraConfig = ''
      Host *
        IdentityAgent ~/.1password/agent.sock
        AddKeysToAgent yes
        UseKeychain yes
        
      # Work-specific SSH configuration
      Host *.company.com
        User deployment
        IdentitiesOnly yes
        IdentityFile ~/.ssh/work_key
        
      # Personal projects
      Host github.com
        User git
        IdentitiesOnly yes
        IdentityFile ~/.ssh/personal_key
        
      # Production servers
      Host prod-*
        User admin
        Port 2222
        IdentitiesOnly yes
        IdentityFile ~/.ssh/production_key
        StrictHostKeyChecking yes
    '';
    
    # Host-specific configurations
    matchBlocks = {
      "*.internal" = {
        user = "deployment";
        identityFile = "~/.ssh/internal_key";
        proxyCommand = "op run -- ssh-proxy %h %p";
      };
    };
  };
  
  # SSH key provisioning with different access levels
  programs.onepassword-secrets.secrets = {
    "personalKey" = {
      path = ".ssh/personal_key";
      reference = "op://Personal/SSH Keys/github-key";
      mode = "0600";
    };
    
    "workKey" = {
      path = ".ssh/work_key";
      reference = "op://Work/SSH Keys/company-key";
      mode = "0600";
    };
    
    "productionKey" = {
      path = ".ssh/production_key";
      reference = "op://Production/SSH Keys/server-key";
      mode = "0600";
    };
  };
}
```

### Integration with Development Tools
```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/opnix.nix
  ];
  
  # Development tool integration
  programs.onepassword-secrets.secrets = {
    # GitHub CLI authentication
    "ghToken" = {
      path = ".config/gh/hosts.yml";
      reference = "op://Development/GitHub/gh-hosts-config";
      mode = "0600";
    };
    
    # Docker registry authentication
    "dockerConfig" = {
      path = ".docker/config.json";
      reference = "op://Development/Docker/registry-config";
      mode = "0600";
    };
    
    # Terraform cloud token
    "terraformToken" = {
      path = ".terraform.d/credentials.tfrc.json";
      reference = "op://Infrastructure/Terraform/cloud-token";
      mode = "0600";
    };
    
    # API keys for various services
    "openaiKey" = {
      path = ".config/openai/api_key";
      reference = "op://Development/OpenAI/api-key";
      mode = "0600";
    };
  };
  
  # Shell integration for secrets
  programs.zsh.initExtra = ''
    # Load secrets into environment when needed
    load_dev_secrets() {
      export GITHUB_TOKEN=$(op read "op://Development/GitHub/personal-access-token")
      export DOCKER_PASSWORD=$(op read "op://Development/Docker/password")
      export TERRAFORM_TOKEN=$(op read "op://Infrastructure/Terraform/cloud-token")
    }
    
    # Conditional secret loading
    if command -v op &> /dev/null && op account list &> /dev/null; then
      load_dev_secrets
    fi
  '';
}
```

## Security Best Practices

### Vault Organization
Organize secrets in 1Password vaults by access level and purpose:

```
Personal/           # Personal accounts and keys
├── SSH Keys/
├── Personal Accounts/
└── Home Services/

Work/              # Work-related secrets
├── SSH Keys/
├── API Tokens/
├── Database Credentials/
└── Service Accounts/

Production/        # Production environment secrets
├── SSH Keys/
├── Database Credentials/
├── API Keys/
└── Certificates/

Development/       # Development environment secrets
├── API Keys/
├── Test Databases/
└── Development Tools/
```

### Access Control
```nix
# Example of role-based secret access
programs.onepassword-secrets.secrets = {
  # Only load production secrets on production machines
  "prodDB" = lib.mkIf (config.networking.hostName == "prod-server") {
    path = ".config/database/production.conf";
    reference = "op://Production/Database/connection-string";
    mode = "0600";
  };
  
  # Development secrets only on dev machines
  "devAPI" = lib.mkIf (builtins.elem config.networking.hostName ["dev-laptop" "dev-desktop"]) {
    path = ".config/api/development.key";
    reference = "op://Development/API/dev-key";
    mode = "0600";
  };
};
```

### Secret Rotation
```bash
# Regular secret rotation workflow
# 1. Generate new secret in 1Password
# 2. Update reference in configuration
# 3. Rebuild system to provision new secret
# 4. Verify functionality
# 5. Revoke old secret
```

## Troubleshooting

### 1Password CLI Issues

#### Authentication Problems
```bash
# Check 1Password CLI status
op account list

# Sign in to 1Password
op signin

# Test secret access
op read "op://Private/SSH Key/private key"

# Check service account token
op whoami
```

#### Service Account Configuration
```bash
# Verify service account token
cat ~/.config/op/service-account-token

# Test service account access
OP_SERVICE_ACCOUNT_TOKEN=$(cat ~/.config/op/service-account-token) op account list

# Check vault access
op vault list
```

### SSH Integration Issues

#### SSH Agent Not Working
```bash
# Check 1Password SSH agent status
ls -la ~/.1password/agent.sock

# Test SSH agent
ssh-add -l

# Check 1Password desktop app SSH agent setting
# Enable SSH agent in 1Password > Settings > Developer > SSH Agent
```

#### Key Permission Problems
```bash
# Check SSH key permissions
ls -la ~/.ssh/

# Fix permissions if needed
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
```

### Secret Provisioning Issues

#### Secrets Not Loading
```bash
# Check opnix service status
systemctl --user status opnix

# Test secret provisioning manually
op run -- cat ~/.ssh/id_ed25519

# Check file permissions
ls -la ~/.ssh/id_ed25519
ls -la ~/.config/op/
```

#### Reference Resolution Errors
```bash
# Test reference format
op read "op://Private/SSH Key/private key"

# Check vault and item names
op item list --vault Private

# Verify field names
op item get "SSH Key" --vault Private
```

### Integration Issues

#### Git Signing Problems
```bash
# Test Git signing configuration
git config --list | grep -i sign

# Test commit signing
git commit --allow-empty -m "test commit" -S

# Check SSH key for signing
ssh-keygen -Y sign -f ~/.ssh/id_ed25519 -n git test.txt
```

#### Environment Variable Issues
```bash
# Check environment variables
env | grep OP_

# Test service account token loading
source ~/.config/op/service-account-token
echo $OP_SERVICE_ACCOUNT_TOKEN
```

## Performance Considerations

### Secret Caching
```nix
# Optimize secret access with caching
home.sessionVariables = {
  # Cache frequently used secrets
  OP_CACHE_DIR = "${config.home.homeDirectory}/.cache/op";
};
```

### Lazy Loading
```nix
# Load secrets only when needed
programs.zsh.initExtra = ''
  # Lazy load secrets function
  load_secrets() {
    if [ ! -f ~/.cache/secrets_loaded ]; then
      op run -- true  # Trigger secret provisioning
      touch ~/.cache/secrets_loaded
    fi
  }
  
  # Load on first use of development commands
  alias git='load_secrets && command git'
  alias docker='load_secrets && command docker'
'';
```

## Integration with System Configuration

### With Impermanence
Opnix works well with impermanence since secrets are provisioned at runtime:
- No secrets stored in persistent storage
- Automatic reprovisioning after system reset
- Secrets exist only in memory during session

### With Development Workflow
```nix
# Integration with development environment
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};

# Project-specific .envrc files can load secrets
# echo 'eval "$(op inject -i .env.template)"' > .envrc
```

### Security Advantages

#### Zero-Knowledge Architecture
- Secrets never stored in Nix configuration
- Runtime provisioning from encrypted vault
- Automatic cleanup on session end

#### Multi-Device Synchronization
- 1Password handles secret synchronization
- Same configuration works across devices
- Consistent access control

#### Audit Trail
- 1Password provides access logging
- Secret usage tracking
- Compliance reporting capabilities

The opnix module provides secure, convenient secret management that integrates seamlessly with development workflows while maintaining zero-knowledge security principles and audit capabilities.