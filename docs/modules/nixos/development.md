# development.nix - Development Tools and Environments

**Location:** `modules/nixos/development.nix`

## Purpose

Provides system-level development tools and programming environments for software development. This module is designed to be conditionally enabled on desktop and laptop hosts where development work is performed.

## Dependencies

- **External:** nixpkgs development packages, container runtime
- **Integration:** Works with desktop/laptop modules, avoided on servers

## Configuration Options

### `development.enable`
- **Type:** `boolean`
- **Default:** `false`
- **Description:** Enable development tools and environments

**Note:** This module must be explicitly enabled and is not activated by default.

## Features

### Core Development Tools

#### Build Systems and Compilers
```nix
environment.systemPackages = with pkgs; [
  # Core compilers
  gcc                    # GNU Compiler Collection
  clang                  # LLVM Clang compiler
  gnumake               # GNU Make build tool
  cmake                 # Cross-platform build system
  pkg-config            # Package configuration tool
];
```

#### Version Control
```nix
environment.systemPackages = with pkgs; [
  git                   # Distributed version control
];
```

### Programming Languages and Runtimes

#### System-Wide Language Support
```nix
environment.systemPackages = with pkgs; [
  # Python ecosystem
  python3               # Python 3 interpreter
  uv                   # Modern Python package management
  
  # JavaScript/Node.js ecosystem
  nodejs               # Node.js runtime
  nodePackages.npm     # npm package manager
  
  # Systems programming
  go                   # Go programming language
  rustc                # Rust compiler
  cargo                # Rust package manager
];
```

**Note:** Node.js and npm are provided system-wide to avoid conflicts with user-level Home Manager packages.

### Container Development

#### Podman Configuration
```nix
virtualisation.podman = {
  enable = true;
  dockerCompat = true;    # Docker CLI compatibility
};

environment.systemPackages = with pkgs; [
  podman                # Container runtime
  podman-compose        # Docker Compose alternative
];
```

### System Optimizations

#### Development-Friendly Kernel Parameters
```nix
boot.kernel.sysctl = {
  "fs.inotify.max_user_watches" = 524288;    # For file watchers in IDEs
  "vm.max_map_count" = 262144;               # For containers and dev tools
};
```

These parameters optimize the system for development workflows:
- **Inotify watches:** Increased limit for file monitoring in IDEs and build tools
- **Memory mapping:** Higher limits for containers and memory-mapped development tools

## Usage Examples

### Basic Development Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/development.nix
  ];
  
  # Enable development tools
  development.enable = true;
}
```

### Desktop Development Environment
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/development.nix
  ];
  
  # Enable both desktop and development features
  desktop.enable = true;
  development.enable = true;
  
  # Add IDE and additional development tools
  environment.systemPackages = with pkgs; [
    vscode
    jetbrains.idea-ultimate
    android-studio
  ];
}
```

### Container Development
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Add container development tools
  environment.systemPackages = with pkgs; [
    docker-compose
    kubernetes
    kubectl
    k9s
    helm
  ];
  
  # Enable additional virtualization
  virtualisation = {
    libvirtd.enable = true;
    docker.enable = false;  # Use Podman instead
  };
}
```

### Language-Specific Development
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Add language-specific tools
  environment.systemPackages = with pkgs; [
    # Rust development
    rustfmt
    rust-analyzer
    clippy
    
    # Go development
    gopls
    golangci-lint
    
    # Python development
    black
    mypy
    pylint
    
    # JavaScript development
    eslint
    prettier
    typescript
  ];
}
```

## Advanced Configuration

### Custom Development Environment
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Create development user group
  users.groups.developers = {};
  users.users.${username}.extraGroups = [ "developers" ];
  
  # Development-specific services
  services = {
    # Enable database for development
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';
    };
    
    # Redis for caching
    redis = {
      enable = true;
      bind = "127.0.0.1";
    };
  };
}
```

### Cross-Compilation Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Enable cross-compilation
  nixpkgs.config.allowUnsupportedSystem = true;
  
  # Add cross-compilation toolchains
  environment.systemPackages = with pkgs; [
    # ARM development
    pkgsCross.aarch64-multiplatform.gcc
    
    # Windows cross-compilation
    pkgsCross.mingw32.gcc
    
    # Additional architectures
    qemu
    crossover
  ];
}
```

### Performance Development Setup
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Performance and profiling tools
  environment.systemPackages = with pkgs; [
    # Performance analysis
    perf-tools
    valgrind
    gdb
    lldb
    
    # Benchmarking
    hyperfine
    criterion
    
    # Memory profiling
    massif-visualizer
    heaptrack
  ];
  
  # Enable performance counters
  boot.kernelParams = [
    "perf_event_paranoid=1"
  ];
}
```

## Integration with Other Modules

### With Desktop Module
When used with desktop environments:
- Provides CLI development tools that complement GUI IDEs
- Container support integrates with desktop applications
- File watchers work with desktop file managers

### With User Configuration
Development tools are installed system-wide but can be complemented by user-level packages:
```nix
# In Home Manager configuration
home.packages = with pkgs; [
  # User-specific development tools
  neovim
  tmux
  zellij
  direnv
  nix-direnv
];
```

### With Impermanence
Development caches and project data should be persisted:
```nix
# In impermanence configuration
environment.persistence."/persist".users.${username} = {
  directories = [
    ".cargo"           # Rust cargo cache
    ".npm"             # npm cache
    ".cache/go-build"  # Go build cache
    "Development"      # Project workspace
    ".local/share/containers"  # Container images
  ];
};
```

## Language-Specific Setups

### Python Development
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Python development environment
  environment.systemPackages = with pkgs; [
    # Python versions
    python38
    python39
    python310
    python311
    
    # Package managers
    uv                    # Modern Python package management
    pipenv               # Virtual environment management
    poetry               # Dependency management
    
    # Development tools
    black                # Code formatter
    mypy                 # Type checker
    pylint               # Linter
    pytest               # Testing framework
  ];
  
  # Python virtual environment support
  environment.variables = {
    PIP_USER = "1";
    PYTHONPATH = "${pkgs.python3}/lib/python3.11/site-packages";
  };
}
```

### Node.js Development
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Node.js development tools
  environment.systemPackages = with pkgs; [
    # Node.js versions (use nodePackages for tools)
    nodejs_18
    nodejs_20
    
    # Package managers
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    
    # Development tools
    nodePackages.typescript
    nodePackages.eslint
    nodePackages.prettier
    nodePackages.nodemon
    
    # Build tools
    nodePackages.webpack
    nodePackages.parcel
    nodePackages.vite
  ];
}
```

### Rust Development
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [
    ../../modules/nixos/development.nix
  ];
  
  development.enable = true;
  
  # Rust development environment
  environment.systemPackages = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    
    # Additional Rust tools
    cargo-watch
    cargo-edit
    cargo-audit
    cargo-outdated
    
    # Cross-compilation targets
    cargo-cross
  ];
  
  # Rust environment variables
  environment.variables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustcSrc}";
    CARGO_HOME = "$HOME/.cargo";
  };
}
```

## Troubleshooting

### Container Issues
```bash
# Check Podman status
systemctl status podman

# Test container functionality
podman run hello-world

# Check container storage
podman system df
```

### File Watcher Limits
```bash
# Check current limits
cat /proc/sys/fs/inotify/max_user_watches

# Increase temporarily
sudo sysctl fs.inotify.max_user_watches=524288
```

### Language Runtime Issues
```bash
# Python environment
python3 --version
pip3 --version

# Node.js environment  
node --version
npm --version

# Rust environment
rustc --version
cargo --version
```

### Build System Problems
```bash
# Check compiler availability
gcc --version
clang --version

# Test make functionality
make --version

# Verify pkg-config
pkg-config --version
```

## Performance Considerations

### Build Performance
- **Parallel builds:** Use `-j$(nproc)` for make-based builds
- **Incremental builds:** Configure IDEs for incremental compilation
- **Cache management:** Regularly clean language-specific caches

### Container Performance
- **Podman:** Rootless containers have some performance overhead
- **Image storage:** Monitor container image disk usage
- **Network:** Container networking may impact local development

### Memory Usage
Development tools can be memory-intensive:
- **IDEs:** Modern IDEs require significant RAM
- **Compilers:** Large projects may need substantial memory
- **Containers:** Running multiple containers increases memory usage

## Security Considerations

### Container Security
- **Rootless Podman:** Default configuration provides good security isolation
- **Image sources:** Only use trusted container registries
- **Volume mounts:** Be cautious with host directory mounts

### Development Data
- **Source code:** Ensure proper version control and backups
- **Credentials:** Never commit secrets to version control
- **Network services:** Development databases should not be exposed externally

### System Access
- **Development groups:** Limit membership to necessary users
- **Sudo access:** Avoid running development tools as root
- **File permissions:** Maintain appropriate permissions on development files