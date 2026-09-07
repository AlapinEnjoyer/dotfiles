# dotfiles

Personal dotfiles, with an incremental Nix migration for macOS alongside the
existing Hyprland/Stow configuration.

## macOS: Home Manager

The `ayrton@mini` configuration targets an Apple Silicon Mac mini. Shared Home
Manager modules install the terminal packages and manage Zsh, Powerlevel10k,
completions, tmux, mise's global configuration, and user-level Nix settings.
Homebrew applications and macOS system settings remain managed separately.

The Home Manager target is derived from the actual account and macOS local hostname
with `whoami` and `scutil --get LocalHostName`. The host module's `home.username`
and `home.homeDirectory` must still match the actual local account.

Nix must already be installed. Run these commands from this repository.

### Shared modules

```text
hosts/mini/home.nix                 Account details and module imports
modules/terminal/default.nix        Shared terminal entry point and Nix settings
modules/terminal/packages.nix       General CLI packages
modules/terminal/mise.nix           Mise installation, integration, and latest tools
modules/terminal/tmux.nix           tmux package and native configuration
modules/terminal/zsh/default.nix    Zsh, prompt, plugins, history, and aliases
modules/terminal/zsh/fzf.nix        Fzf integration, colors, and previews
modules/terminal/zsh/functions.zsh  Custom functions and keybindings
modules/terminal/zsh/completions/   Handwritten completion definitions
modules/darwin/default.nix          Homebrew environment and completion path
config/p10k.zsh                     Preserved Powerlevel10k configuration
config/tmux.conf                    Preserved tmux configuration
```

Both Macs should import `modules/terminal` and `modules/darwin`. A Linux host can
import `modules/terminal` without the Darwin module, then add its own desktop
settings. Only `mini` is configured and tested so far; add other flake outputs
after confirming their account details and architecture. These are Home Manager
modules, including the Darwin-specific one; nix-darwin is not installed yet.
The root `.zshrc` is retained as legacy configuration, not the source for the
managed Mac shell. Shared shell changes belong in `modules/terminal/zsh`.

### First activation

Build using the pinned Home Manager input, without needing Home Manager installed
beforehand:

```sh
git add flake.nix hosts/mini/home.nix modules config/tmux.conf config/p10k.zsh
nix --extra-experimental-features 'nix-command flakes' build \
  '.#homeConfigurations."ayrton@mini".activationPackage'
./result/activate
```

Git-backed flakes omit untracked files, so stage the new Nix files before building.
Staging does not create a commit. Keep tracked files free of secrets: flake source
is copied into the Nix store. Stage the generated `flake.lock` and commit it
alongside the configuration to preserve the pinned inputs.

The build does not change the active home configuration; `./result/activate` does.
If activation reports an existing-file conflict, back up and reconcile that file
rather than forcing an overwrite.

Open a new terminal and verify:

```sh
home-manager --version
just --version
nix config show experimental-features
```

If `home-manager` is not on PATH yet, it can be invoked directly as
`~/.nix-profile/bin/home-manager`. Review shell initialization before adding
duplicate PATH setup.

### Subsequent changes

After the Nix source files are tracked by Git:

```sh
home-manager build --flake '.#ayrton@mini'
home-manager switch --flake '.#ayrton@mini'
```

Review the build before switching. Update inputs deliberately with
`nix flake update`, review `flake.lock`, and rebuild before activating.
Do not bump `home.stateVersion` as part of ordinary updates.

### Everyday commands

Run `just` to list recipes. The Home Manager target is derived from `whoami` and
macOS's `LocalHostName`, avoiding the network-resolved value returned by `hostname`.

| Command | Action |
| --- | --- |
| `just build-hm` | Build without activation |
| `just switch-hm-dry-run` | Preview activation without applying it |
| `just switch-hm` | Build and activate |
| `just test-zsh` | Check the active shell in a new interactive Zsh; no model requests |
| `just update` | Update the lock file; does not activate |
| `just generations` | List Home Manager rollback generations |
| `just gc` | Delete unreachable store paths, retaining rooted generations |
| `just optimise` | Hard-link identical store files to save space |

For a future host, add its matching `user@LocalHostName` output to the flake and
run the same recipe on that host. Darwin recipes will be added when nix-darwin is configured.

Garbage collection does not delete profile generations. It can still remove
unrooted development-shell dependencies and build outputs, requiring downloads or
rebuilds later. No recipe expires generations or performs destructive full cleanup.

The inputs currently use matching stable 26.05 branches for a conservative starting
point. Tracking Home Manager's default branch alongside `nixos-unstable` is another
valid choice. Both approaches pin exact revisions in `flake.lock`; branches control
where future updates come from. Change the two inputs together when changing release
tracks, and keep `home.stateVersion` unchanged unless deliberately migrating state.

Keep Homebrew and mise during migration. Add shared modules and other hosts only
as needed; the existing Linux/Stow setup below remains unchanged.

### Migration status

The first CLI batch is managed by Nix. Remove its global mise declarations only
after successful activation and executable-path checks. Installed mise copies can
remain temporarily for recovery; project-local mise declarations can still override
the default provider. Package versions come from `flake.lock`, not the former mise
selectors, including the former eza 0.23.4 pin.

| Tool | Migrated from mise | Current Nix version |
| --- | --- | --- |
| tmux | 3.7b | 3.6a |
| bat | 0.26.1 | 0.26.1 |
| fd | 10.5.0 | 10.4.2 |
| ripgrep | 15.2.0 | 15.1.0 |
| eza | 0.23.4 | 0.23.4 |
| fzf | 0.74.3 | 0.72.0 |
| zoxide | 0.10.0 | 0.9.9 |
| glow | 3.0.0 | 2.1.2 |

These versions describe the first migration batch, not additional version pins.
The shared shell puts the Nix profile before inherited mise shims, then activates
mise so selected project runtimes can still take precedence. Existing mise
installations are retained for recovery; do not re-add global declarations for
tools that Nix now owns unless deliberately changing that ownership.

Mise manages Node, pnpm, Rust, OpenTofu, Terragrunt, OpenCode, gh, uv, and ffmpeg.
All global mise tool declarations use `latest` to track upstream releases rather
than stable nixpkgs versions. Run `mise upgrade` to update installed versions;
`latest` does not automatically upgrade tools at shell startup. Project-local
version requirements can still override the global defaults.
`hf`, `semble`, and `trv` remain uv-managed tools; `rustlings` is Cargo-installed.
Homebrew and GUI apps are unchanged.

Home Manager installs mise itself from pinned nixpkgs and owns
`~/.config/mise/config.toml`. Its nine `latest` declarations live in
`modules/terminal/mise.nix`; edit that module and run `just switch-hm` instead of
`mise use -g`, which would try to modify the read-only generated config.
Use `mise install` on a new host and `mise upgrade` for subsequent tool updates.
Home Manager activation does not install or upgrade mise-managed tools. Their
versions are independent of the pinned mise executable (currently 2026.5.12).
Existing external mise installations are retained but are no longer the shell's
default. Update mise itself through Nix, not `mise self-update`.

The shared shell replaces Zinit with Nix-packaged Powerlevel10k, zsh-completions,
fzf-tab, autosuggestions, and syntax highlighting. Existing Zinit files are left on
disk but are no longer sourced or updated at startup. Fzf and zoxide integration
each have one owner in Home Manager, as does mise activation. Nix supplies mise's
completion; uv/gh completion generation remains explicit for mise-managed tools.

The laptop's functions, aliases, and history exclusions are the shared baseline.
`ask` uses the laptop's model list/default and preserves separate CLI arguments.
Its pipeline now propagates OpenCode failures. Model availability is provider-side
and has not been tested with real requests. The mini's Powerlevel10k configuration
was copied unchanged; the laptop's prompt configuration was not available to compare.

### Shell and completion ownership

Home Manager owns `~/.zshrc`, `~/.zshenv`, `~/.zprofile` on macOS, and `~/.p10k.zsh`.
Edit the repository and switch, rather than editing the generated symlinks. Avoid
running `p10k configure` against the immutable managed file; make prompt changes
in `config/p10k.zsh`. The account's login shell remains `/bin/zsh`; installing Nix's
Zsh does not change it. Both shells should load the same managed home configuration.

Completion directories are set before the single `compinit` invocation:

- `~/.config/zsh/completions` links to this repo's handwritten completions, such as
  `_ask`. Add files with a `#compdef command` header in the repository.
- Nix profile completion directories supply definitions for Nix-managed commands.
- Nix's zsh-completions package supplies additional definitions.
- The macOS module adds Homebrew's completion directory for retained Brew tools.
- Uv and gh generate completions from their active executables after
  `compinit`. No timestamp-based initialization cache is used.

Do not generate files into the Nix store or any package-managed completion
directory. After adding a handwritten completion, stage it, run `just switch-hm`,
then open a new terminal. `zcompreset` removes the Zsh completion dump and restarts
Zsh if a reset is needed. The old `~/.cache/zinit/completions` directory is no longer
used; it was empty on the mini at migration time.

Explicit startup ordering keeps instant prompt early, fzf-tab before
autosuggestions, and tool completion generation after mise activation. Completion
setup lives beside `compinit`. Home Manager handles the integrations and loads
syntax highlighting last. Fzf's `**` completion handler wraps Tab and delegates
normal completion to fzf-tab.

Fzf-tab is sourced from nixpkgs' pinned source without its optional native module.
This keeps it compatible with system, Homebrew, and Nix Zsh builds, which can use
different native-module formats. It does not download or compile plugins at startup.

Run `just test-zsh` in a terminal after switching. It checks completion registration,
widgets, history, previews, and custom functions, using stubs instead of remote
OpenCode requests. Also visually check Tab, Ctrl-R, Ctrl-T, Alt-C, autosuggestions,
highlighting, and the prompt in Ghostty.

Alt-C: press **Esc, then c** promptly to pick a directory with fzf and change into it.

### Backups and recovery

The mise configuration handoff backed up the unmanaged file as
`~/.config/mise/config.toml.nix-mise-migration-backup`. Installed tools were unchanged.

The initial handoff preserves the old files as `~/.tmux.conf.nix-migration-backup`
and `~/.config/mise/config.toml.nix-migration-backup`, outside Git. Restoring an older
Home Manager generation alone does not restore the manually edited mise config.

The initial shell handoff used the following command after a build and dry run:

```sh
home-manager switch --flake '.#ayrton@mini' -b nix-shell-migration-backup
```

This backed up `.zshrc`, `.zshenv`, `.zprofile`, and `.p10k.zsh` beside the originals
before replacing them. Do not reuse that suffix to overwrite an earlier backup.
Use ordinary `just switch-hm` for subsequent changes.

Keep a working terminal open during shell changes. `/bin/zsh -f` bypasses user
`.zshrc` for repair. Later Home Manager generations can restore earlier managed
shell versions, but a rollback to before the first shell handoff does not recreate
the original unmanaged files: those require the backups. Do not run garbage
collection or delete old generations until the migration is stable.

## Linux: Existing Hyprland Setup

## Prerequisites

Install a nerd font for icon support. For example MartianMono Nerd Font:
- Extract to `/usr/share/fonts`
- Update cache: `fc-cache -fv`

### Install yay (if not already installed)

```zsh
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si && cd .. && rm -rf yay
```

## Installation

Install all packages:

```zsh
yay -S stow blueman hypridle hyprlock hyprpaper hyprland hyprshot ghostty dolphin zen-browser-bin rofi-wayland waybar fastfetch brightnessctl wlogout fzf eza bat fd ripgrep noto-fonts-emoji mise networkmanager network-manager-applet
```

Clone and stow:

```zsh
git clone https://github.com/AlapinEnjoyer/dotfiles.git
cd dotfiles
stow backgrounds conf fontconfig ghostty hypridle hyprland hyprlock hyprpaper waybar rofi scripts wlogout
```
