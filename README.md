# dotfiles

Nix flake for two machines:

| Target | System | Configuration |
| --- | --- | --- |
| `ayrton@mini` | Apple Silicon macOS | Home Manager + nix-darwin |
| `ayrton@uno` | x86_64 Arch Linux | Standalone Home Manager |

Nix owns the user environment. The host package manager owns system drivers,
services, and platform-specific exceptions.

## Ownership

| Owner | Scope |
| --- | --- |
| Home Manager | Zsh, Powerlevel10k, tmux, Ghostty, fonts, CLI tools, mise, OpenCode, and desktop user configuration |
| Nix-darwin | Mini system settings and declared Homebrew casks |
| Arch/pacman/AUR | Uno kernel, AMDGPU/Mesa, ROCm, SDDM, Bluetooth, audio, Waybar, Hyprlock/PAM, Zen, and system services |
| mise | OpenCode, uv, Node, pnpm, Rust; Mini-only upstream Metal llama.cpp |

Uno's RX 9070 uses the stable TheRock-based ROCm Core SDK at
`/opt/rocm/core`. `ROCM_PATH` and `ROCM_HOME` are set only on Uno. Uno's
llama.cpp HIP build is compiled locally rather than installed by mise.

## Layout

```text
flake.nix                 Targets and pinned inputs
hosts/                    Host-specific Home Manager and Darwin settings
modules/terminal/         Shared shell, terminal, mise, OpenCode, and tmux
modules/linux/            Uno desktop and NixGL session integration
modules/darwin/           Mini defaults
modules/programs/         Shared program modules
config/                   Native Hyprland, Waybar, Rofi, Wlogout, and fonts
docs/                     Full macOS and Arch setup notes
tests/                    Isolated smoke tests
justfile                  Build, switch, test, and maintenance recipes
```

## Bootstrap

Use the detailed host guides for first activation, recovery, package ownership,
and system prerequisites:

- [macOS setup](docs/macos-setup.md)
- [Arch setup](docs/linux-setup.md)

For an untracked working tree, bootstrap with `path:.` so new files are included:

```sh
nix --extra-experimental-features 'nix-command flakes' build \
  'path:.#homeConfigurations."ayrton@mini".activationPackage'
./result/activate
```

On Uno, use the equivalent `ayrton@uno` target. Inspect the tree before using a
path flake because ignored files are copied into the Nix store.

## OpenCode

OpenCode and uv are installed by mise. Home Manager owns their configuration;
`programs.opencode.package` is intentionally empty to avoid installing a second
binary. Semble runs through the pinned command:

```sh
uvx --from 'semble[mcp]==0.5.6' semble
```

Keep the OpenCode legacy-config conflict checks enabled. See the host guides for
backup and recovery procedures.
