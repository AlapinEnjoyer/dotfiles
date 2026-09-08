hostname := if os() == "macos" { shell('scutil --get LocalHostName') } else { shell('hostnamectl --static') }
user := shell('whoami')

# List the available recipes and their descriptions.
default:
    @just --list

# Build the Home Manager configuration without changing the active generation.
build-hm:
    home-manager build --flake '.#{{user}}@{{hostname}}' --print-build-logs

# Build the nix-darwin system without changing the active system.
build-darwin:
    nix build '.#darwinConfigurations."{{user}}@{{hostname}}".system' --print-build-logs

# Build and activate the Home Manager configuration for the selected target.
switch-hm:
    home-manager switch --flake '.#{{user}}@{{hostname}}' --print-build-logs

# Preview required builds/downloads, not system or Homebrew activation.
build-darwin-dry-run:
    nix build '.#darwinConfigurations."{{user}}@{{hostname}}".system' --dry-run

# Build and activate the nix-darwin system.
switch-darwin:
    sudo darwin-rebuild switch --flake '.#{{user}}@{{hostname}}' --print-build-logs

# Preview a Home Manager activation without changing the active generation.
switch-hm-dry-run:
    home-manager switch --flake '.#{{user}}@{{hostname}}' --dry-run

# Test the active shell's completions, widgets, and functions without model requests.
test-zsh:
    zsh -ic 'source tests/zsh-smoke.zsh'

# Refresh flake inputs and rewrite flake.lock without activating a configuration.
update:
    nix flake update

# List Home Manager generations available to inspect or roll back to.
generations:
    home-manager generations

# Delete unreachable store paths while keeping paths rooted by retained generations.
gc:
    nix store gc --verbose

# Hard-link identical store files to reduce disk usage without deleting paths.
optimise:
    nix store optimise --verbose
