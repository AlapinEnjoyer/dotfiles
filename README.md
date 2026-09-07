# dotfiles

Personal dotfiles, with an incremental Nix migration for macOS alongside the
existing Hyprland/Stow configuration.

## macOS: Home Manager

The `ayrton@mini` configuration targets an Apple Silicon Mac mini. Shared Home
Manager modules install the terminal packages and manage Zsh, Powerlevel10k,
completions, tmux, Ghostty configuration and font, mise's global configuration,
and user-level Nix settings.
Homebrew applications and macOS system settings are managed by nix-darwin, except
for Ghostty, which Home Manager installs from Nix.

The Home Manager target is derived from the actual account and macOS local hostname
with `whoami` and `scutil --get LocalHostName`. The flake currently declares only
`ayrton@mini`; the `user` value is passed into Home Manager and used to construct
the account's `home.username` and `home.homeDirectory`, so it must match the actual
local account.

Nix must already be installed. Run these commands from this repository.
See [macOS setup](docs/macos-setup.md) for the complete fresh-machine bootstrap,
tool ownership model, update workflow, and non-declarative state.

### Shared modules

```text
hosts/mini/home.nix                 Account details, Home Manager enablement, and imports
hosts/mini/configuration.nix         nix-darwin system and Homebrew configuration
modules/darwin/defaults.nix          Shared macOS Finder and Dock preferences
modules/terminal/default.nix        Shared CLI packages, terminal imports, and Nix settings
modules/terminal/mise.nix           Mise installation, integration, and latest tools
modules/terminal/opencode/          OpenCode configuration, agent, and instructions
modules/terminal/tmux.nix           tmux package and native configuration
modules/programs/ghostty.nix        Ghostty settings and MartianMono Nerd Font
modules/terminal/zsh/default.nix    Zsh, prompt, plugins, history, and aliases
modules/terminal/zsh/fzf.nix        Fzf integration, colors, and previews
modules/terminal/zsh/functions.zsh  Custom functions and keybindings
modules/terminal/zsh/completions/   Handwritten completion definitions
modules/terminal/zsh/homebrew.nix   Homebrew environment and completion path
config/p10k.zsh                     Preserved Powerlevel10k configuration
config/tmux.conf                    Preserved tmux configuration
```

The mini imports `modules/terminal` and explicitly opts into
`modules/terminal/zsh/homebrew.nix` for Homebrew shell integration. It also
explicitly imports `modules/programs/ghostty.nix`; Ghostty is not part of the shared
terminal bundle. A Linux host can import `modules/terminal`, then add its own
desktop settings. Host modules own Home Manager enablement. Only `mini` is
configured and tested so far; add other flake outputs after confirming their
account details and architecture. These are Home Manager modules, including the
Homebrew shell integration. The `darwinConfigurations` output owns
macOS system configuration and Homebrew; the `homeConfigurations` output owns the
user environment.
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

### First nix-darwin activation

Build the system first, then use its rebuild command to switch as root:

```sh
nix build '.#darwinConfigurations."ayrton@mini".system'
sudo ./result/sw/bin/darwin-rebuild switch --flake '.#ayrton@mini'
```

This installs the nix-darwin system profile and gives subsequent shells the
`darwin-rebuild` command. The switch command evaluates/builds the flake again;
do not change the configuration between reviewing the build and switching.
`just build-darwin-dry-run` previews builds/downloads only, not activation.
This nix-darwin version does not provide an activation dry-run. Homebrew uses
`cleanup = "zap"`, so review the declared cask inventory before activation;
undeclared formulas and casks, including Homebrew-defined cask data, are removed.

If the first switch reports unexpected `/etc/bashrc` and `/etc/zshrc`, stop and
review both files and `result/etc/{bashrc,zshenv,zprofile,zshrc}`, plus the store
file sourced as `set-environment`. On this mini the existing files contain a Nix
installer block followed by standard macOS content; their hashes are not in the
pinned nix-darwin allowlist. Do not bypass the check or add their hashes blindly.

With `nix.enable = false`, nix-darwin leaves the external Nix installation and
daemon management alone, but still generates the shell environment. Its Bash rc
and Zsh env source `set-environment`, which supplies `~/.nix-profile/bin`,
`/run/current-system/sw/bin`, `/nix/var/nix/profiles/default/bin`, `NIX_PROFILES`,
and the certificate path. The old `nix-daemon.sh` block sets shell variables; it
does not start the daemon. The installed `org.nixos.nix-daemon` launchd service
starts it independently. Do not copy the old rc files into `.local` hooks: that
would reintroduce competing initialization. Recheck this on other installations,
especially ones using XDG Nix profiles or custom certificate/PATH settings.

After reviewing and building, keep this terminal open. Run the following only
for these two confirmed conflicts. It checks both destinations (including dangling
symlinks) before moving anything, refuses non-regular/symlink sources, and uses
macOS `mv -n` to avoid overwriting backups. If a backup already exists, inspect it
and choose a fresh suffix in the script rather than deleting it.

```sh
sudo /bin/sh -eu <<'SH'
suffix=.before-nix-darwin
for file in /etc/bashrc /etc/zshrc; do
  test -f "$file" && test ! -L "$file" || {
    printf 'Stop: unexpected source %s\n' "$file" >&2; exit 1;
  }
  if test -e "$file$suffix" || test -L "$file$suffix"; then
    printf 'Stop: backup already exists: %s\n' "$file$suffix" >&2; exit 1
  fi
done
for file in /etc/bashrc /etc/zshrc; do
  /bin/mv -n "$file" "$file$suffix"
  if test -e "$file" || test -L "$file"; then
    printf 'Stop: source was not moved: %s\n' "$file" >&2; exit 1
  fi
done
SH
# Only after the backup command succeeds:
sudo ./result/sw/bin/darwin-rebuild switch --flake '.#ayrton@mini'
```

The two moves are not atomic. If a move or the retry fails, keep the terminal
open, inspect the state, and resolve the reported problem before retrying; do not
rerun the backup script blindly. To restore an original while its `/etc` path is
still absent, use `sudo /bin/mv -n /etc/bashrc.before-nix-darwin /etc/bashrc`
(and likewise for `zshrc`). Never overwrite a generated symlink or another file
without reviewing it first. These backups are not automatically sourced.
The generated Zsh rc also replaces macOS keybindings/Terminal.app session setup;
Bash retains its Terminal.app hook. Preserve any desired macOS behavior explicitly
rather than sourcing the entire backup.

After a successful switch, open a fresh terminal and run `command -v nix`,
`nix --version`, `nix store ping --store daemon`, and `just test-zsh`. The separate
Home Manager configuration must also be activated for user completion and prompt
setup. A build alone cannot validate live activation or Terminal.app behavior.

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
| `just build-darwin` | Build the nix-darwin system without activation |
| `just switch-hm-dry-run` | Preview activation without applying it |
| `just switch-hm` | Build and activate |
| `just build-darwin-dry-run` | Preview required builds/downloads only |
| `just switch-darwin` | Build and activate nix-darwin; requires `sudo` |
| `just test-zsh` | Check the active shell in a new interactive Zsh; no model requests |
| `just update` | Update the lock file; does not activate |
| `just generations` | List Home Manager rollback generations |
| `just gc` | Delete unreachable store paths, retaining rooted generations |
| `just optimise` | Hard-link identical store files to save space |

For a future host, add its matching `user@LocalHostName` output to the flake and
run the same recipe on that host.

Garbage collection does not delete profile generations. It can still remove
unrooted development-shell dependencies and build outputs, requiring downloads or
rebuilds later. No recipe expires generations or performs destructive full cleanup.

The inputs currently use matching stable 26.05 branches for a conservative starting
point. Tracking Home Manager's default branch alongside `nixos-unstable` is another
valid choice. Both approaches pin exact revisions in `flake.lock`; branches control
where future updates come from. Change the two inputs together when changing release
tracks, and keep `home.stateVersion` unchanged unless deliberately migrating state.

Homebrew declares the Mac mini's remaining GUI casks in
`hosts/mini/configuration.nix`. Activation uses `cleanup = "zap"`, so a future
switch removes undeclared Homebrew formulas or casks and Homebrew-defined cask
data. Mise remains managed by Home Manager. The existing Linux/Stow setup below
remains unchanged.

### Migration status

The first CLI batch is managed by Nix and its former global mise declarations have
been removed. Project-local mise declarations can still override the default
provider. Package versions come from `flake.lock`, not the former mise selectors,
including the former eza 0.23.4 pin.

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

Mise manages Node, pnpm, Rust, OpenTofu, Terragrunt, OpenCode, gh, uv, ffmpeg,
and llama.cpp. The latter uses upstream's b-prefixed GitHub prerelease binaries.
All global mise tool declarations use `latest` to track upstream releases rather
than stable nixpkgs versions. Run `mise upgrade` to update installed versions;
`latest` does not automatically upgrade tools at shell startup. Project-local
version requirements can still override the global defaults.
`hf`, `semble`, and `trv` remain uv-managed tools; `rustlings` is Cargo-installed.
Nix supplies the shared CLI baseline and the Mini-specific CLI tools. Nix-darwin
declares the remaining Homebrew cask inventory and migrates Homebrew itself to
nix-homebrew management. Ghostty is already Nix-managed; other GUI apps remain
casks pending individual migration checks.

llama.cpp is installed through mise and its `llama-server` binary has been
verified. The former Homebrew formula was removed.

The Mac mini's Git identity is declared in `hosts/mini/home.nix`. The existing
`~/.gitconfig` mirrors that identity while preserving its global excludes file and
default-branch setting.

Home Manager installs mise itself from pinned nixpkgs and owns
`~/.config/mise/config.toml`. Its `latest` declarations live in
`modules/terminal/mise.nix`; edit that module and run `just switch-hm` instead of
`mise use -g`, which would try to modify the read-only generated config.
Home Manager activation runs `mise install --yes --cd /` after linking the
configuration, so missing declared tools are installed on a new host. It does not
upgrade already-installed tools; use `mise upgrade` for that. Their versions are
independent of the pinned mise executable (currently 2026.5.12).
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

### Ghostty ownership

Home Manager installs and updates Ghostty through `pkgs.ghostty-bin` and owns
`~/.config/ghostty/config` through `modules/programs/ghostty.nix`. Edit the Nix
module and run `just switch-hm`; do not edit the generated config. Do not install a
second Homebrew copy or Stow the legacy `ghostty/` directory on this Mac. Avoid a
second config under
`~/Library/Application Support/com.mitchellh.ghostty`, which can override settings.

Nix installs `nerd-fonts.martian-mono`; the actual family is
`MartianMono Nerd Font`. Pinned Home Manager automatically copies packaged fonts
into `~/Library/Fonts/HomeManager` on macOS so GUI apps can discover them.
To use MonoLisa later, install your licensed font separately and change
`font-family` in the Nix module to `"MonoLisa"`, then switch. No proprietary font
files belong in this repository or the Nix store.

The initial Ghostty handoff is complete. Subsequent changes use `just switch-hm`.
Reload Ghostty's configuration or open a new window and visually check the font,
Nerd Font icons, theme, transparency, and Cmd-Backspace/Shift-Enter bindings.

### Shell and completion ownership

Home Manager owns `~/.zshrc`, `~/.zshenv`, `~/.zprofile` on macOS, and `~/.p10k.zsh`.
Edit the repository and switch, rather than editing the generated symlinks. Avoid
running `p10k configure` against the immutable managed file; make prompt changes
in `config/p10k.zsh`. The account's login shell remains `/bin/zsh`; installing Nix's
Zsh does not change it. Both shells should load the same managed home configuration.

Completion directories are set before the single `compinit` invocation:

The mini disables nix-darwin's system completion initialization (both `compinit`
and `bashcompinit`) and default SuSE prompt. Home Manager is the sole owner;
other users without Home Manager no longer receive these system defaults.

- `~/.config/zsh/completions` links to this repo's handwritten completions, such as
  `_ask`. Add files with a `#compdef command` header in the repository.
- Nix profile completion directories supply definitions for Nix-managed commands.
- Nix's zsh-completions package supplies additional definitions.
- `modules/terminal/zsh/homebrew.nix` adds Homebrew's completion directory for retained Brew tools.
  It first resolves Homebrew's `Library/Homebrew` to load the matching `_brew`
  completion from nix-homebrew's store tree. Migration can leave a dangling
  prefix `_brew` link; the real definition takes precedence without deleting it.
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
