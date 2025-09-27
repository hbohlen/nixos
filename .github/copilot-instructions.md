# GitHub Copilot Instructions

## Project Overview

This repository is configured with multiple Model Context Protocol (MCP) servers to enhance development capabilities:
- **NixOS MCP**: For package validation and system configuration
- **Brave Search MCP**: For researching issues and finding solutions
- **Sequential Thinking MCP**: For complex problem-solving workflows
- **ByteRover MCP**: For memory management and context preservation

## MCP Server Usage Guidelines

### NixOS MCP Server Usage

**Always validate NixOS packages and configurations using the NixOS MCP tools:**

- Use `nixos_search` to verify package availability before suggesting installations
- Use `nixos_info` to get accurate package details and configuration options
- Check `nixos_channels` to ensure compatibility with the target NixOS version
- For Home Manager configurations, use `home_manager_search` and `home_manager_info`
- For nix-darwin on macOS, use `darwin_search` and `darwin_info`
- Use `nixhub_package_versions` to check version history and compatibility

**Package Validation Rules:**
- Never suggest packages without first verifying they exist using `nixos_search`
- Always check the appropriate channel (stable, unstable) for package availability
- Provide accurate attribute paths from the search results
- Include version information when relevant

### Brave Search MCP Integration

**Use Brave Search for external research and troubleshooting:**

- Use `brave_web_search` for general technical issues and solutions
- Use `brave_news_search` for recent developments or security advisories
- Use `brave_local_search` for location-specific technical resources
- Use `brave_image_search` when visual examples would be helpful
- Use `brave_video_search` for tutorial content or demonstrations
- Use `brave_summarizer` to condense long documentation or research

**Research Guidelines:**
- Search for error messages and solutions before suggesting fixes
- Look up best practices for technologies being used
- Verify configuration examples against current documentation
- Research security implications of suggested changes

### Sequential Thinking MCP Usage

**Apply structured thinking for complex problems:**

- Use `sequential_thinking` for multi-step problem analysis
- Break down complex tasks into logical thought sequences
- Use revision capabilities when reconsidering approaches
- Branch thinking paths for alternative solutions
- Adjust total thought count dynamically as problems evolve

**When to Use Sequential Thinking:**
- Complex system architecture decisions
- Multi-component integration challenges
- Debugging issues with multiple potential causes
- Planning large-scale refactoring or migrations
- Evaluating trade-offs between different approaches

### ByteRover MCP Memory Management

**Leverage memory and context management for consistency:**

- Use `byterover_store_memory` to remember important project decisions
- Use `byterover_search_memory` to recall past solutions and patterns
- Use `byterover_store_knowledge` for reusable technical information
- Use `byterover_planning_create` for project roadmap management
- Use `byterover_task_management` for tracking development tasks
- Use `byterover_context_compose` for maintaining conversation context

**Memory Best Practices:**
- Store recurring patterns and solutions for future reference
- Remember user preferences and coding standards
- Track project-specific conventions and decisions
- Maintain context across multiple development sessions

## Development Workflow Integration

### Issue Analysis Process

1. **Initial Research**: Use Brave Search to understand the problem domain
2. **Package Validation**: Use NixOS MCP to verify any package dependencies
3. **Structured Analysis**: Apply Sequential Thinking for complex issues
4. **Context Storage**: Store findings using ByteRover for future reference

### Solution Development

1. **Research Solutions**: Search for existing patterns and best practices
2. **Validate Dependencies**: Ensure all packages and versions are available
3. **Think Through Implementation**: Use structured thinking for complex changes
4. **Document Decisions**: Store important choices in memory for consistency

### Code Review and Validation

1. **Verify Configurations**: Check NixOS configurations against official sources
2. **Research Best Practices**: Look up current recommended approaches
3. **Consider Alternatives**: Use branching logic for different solution paths
4. **Remember Patterns**: Store successful patterns for reuse

## Coding Standards and Practices

### NixOS Configuration Management

- Always use the most appropriate channel for packages
- Prefer stable packages unless unstable features are specifically needed
- Validate all package attributes and options before suggesting them
- Include proper error handling for optional packages
- Document why specific packages or versions are chosen

### Error Handling and Debugging

- Search for error messages before suggesting solutions
- Use sequential thinking to systematically isolate issues
- Consider multiple potential causes and solutions
- Store successful debugging approaches for future reference

### Documentation and Knowledge Sharing

- Research current best practices before making recommendations
- Store commonly used patterns and solutions
- Document architectural decisions and their rationales
- Maintain context about project-specific conventions

## Tool Integration Priorities

1. **Validation First**: Always verify packages and configurations
2. **Research Driven**: Base suggestions on current, researched information
3. **Structured Thinking**: Apply logical problem-solving for complex issues
4. **Memory Enabled**: Learn from past interactions and decisions
5. **Context Aware**: Maintain consistency across development sessions

## Security and Best Practices

- Research security implications of suggested packages and configurations
- Verify package sources and maintainer reputation
- Consider minimal installation principles
- Document security considerations in memory for future reference
- Use structured thinking to evaluate security trade-offs

## Continuous Learning

- Store successful patterns and solutions for future reference
- Remember user preferences and project-specific requirements
- Track evolving best practices and update stored knowledge
- Maintain awareness of package updates and ecosystem changes
### Build & Workflow
- **Full system rebuild:** `./scripts/rebuild.sh` (preferred, auto-detects host)
- **Manual rebuild:** `sudo nixos-rebuild switch --flake .#hostname`
- **Test build:** `nixos-rebuild build --flake .#hostname`
- **Dry run:** `nixos-rebuild dry-activate --flake .#hostname`
- **Check flake:** `nix flake check`
- Always test with `nixos-rebuild build` before switching

### Nix Conventions & Patterns
- All modules use `{ config, pkgs, lib, inputs, ... }:` signature (always include `...`)
- Use relative imports (e.g., `../../modules/`)
- Filenames: kebab-case; Nix options: camelCase; String vars: snake_case
- 2-space indentation, trailing commas, <100 char lines
- Use `lib.mkDefault` for overridable values, `lib.mkIf` for conditionals
- Use `lib.optionalAttrs` and `lib.optionalString` for conditional logic
- Use `lib.mkOption` for custom options with types
- Never commit secrets; use Opnix/1Password for runtime secrets

### Impermanence & Persistence
- Root is ephemeral (tmpfs); persistent state is opt-in via `/persist`
- See `modules/impermanence.nix` for what is persisted

### Disko & ZFS
- Disk layout and ZFS pools are defined declaratively (see per-host `hardware/disko-zfs.nix` files)
- Update device paths as needed for new hardware

### Home Manager
- User environments are managed via Home Manager modules
- User overlays in `users/` and `modules/home-manager/`

### Security
- Use SSH keys, not passwords (initialPassword is for setup only)
- Never store secrets in the repo

### Adding a New Host (Example)
1. Copy an existing host dir in `hosts/`
2. Update hardware config and host-specific options
3. Add to `flake.nix` outputs
4. Run `./scripts/rebuild.sh`

### Troubleshooting & Testing
- Use `nix flake check` for flake errors
- Validate hardware-specific configs on target hardware
- For ZFS/disko/impermanence issues, check module wiring in `flake.nix`

---
**For more details, see `README.md` and `AGENTS.md`.**
