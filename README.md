# dotfiles

Personal dotfiles, with Home Manager configurations for macOS and Arch Linux.

## macOS: Home Manager

The `ayrton@mini` configuration targets an Apple Silicon Mac mini. Shared Home
Manager modules install the terminal packages and manage Zsh, Powerlevel10k,
completions, tmux, Ghostty configuration and font, mise's global configuration,
and user-level Nix settings.
Homebrew applications and macOS system settings are managed by nix-darwin, except
for Ghostty, which Home Manager installs from Nix.

The Home Manager target is derived from the actual account and macOS local hostname
with `whoami` and `scutil --get LocalHostName`. The macOS target is
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

Both Mini and Uno import `modules/terminal`, which composes independently
importable CLI program modules and shared `home.packages`, including Neovim.
Neovim's aliases live in the shared Zsh module; its config is not managed. Each host separately imports
`modules/programs/ghostty.nix`; Ghostty is not part of the shared CLI bundle.
Program defaults can be overridden by hosts without copying the shared settings. Only Mini opts into
`modules/terminal/zsh/homebrew.nix` for Homebrew shell integration. Host modules own Home
Manager enablement. These are Home Manager modules, including the
Homebrew shell integration. The `darwinConfigurations` output owns
macOS system configuration and Homebrew; the `homeConfigurations` output owns the
user environment.
The root `.zshrc` is retained as legacy configuration, not the source for the
managed shell on either host. Shared shell changes belong in `modules/terminal/zsh`.

### First activation

Build using the pinned Home Manager input, without needing Home Manager installed
beforehand:

```sh
nix --extra-experimental-features 'nix-command flakes' build \
  'path:.#homeConfigurations."ayrton@mini".activationPackage'
./result/activate
```

`path:.` includes new modules and package expressions without staging or committing.
Review the tree for secrets first: path flakes can include ignored and untracked
files in the Nix store. Once all sources are tracked, use the ordinary `.#...`
reference. Keep the existing `flake.lock` unless deliberately updating inputs.

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
data. Mise remains managed by Home Manager on macOS. The Linux handoff below is
separate and does not change Darwin configuration.

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

Nix is the default package owner. It now also supplies Neovim on both hosts,
OpenTofu, Terragrunt, gh, and ffmpeg. Mise supplies OpenCode and uv at `latest`,
project runtimes (Node, pnpm, Rust), and llama.cpp, whose declaration
selects upstream's b-prefixed GitHub prerelease binaries.
All global mise tool declarations use `latest` to track upstream releases rather
than stable nixpkgs versions. Run `mise upgrade` to update installed versions;
`latest` does not automatically upgrade tools at shell startup. Project-local
version requirements can still override the global defaults.
Older imperative `hf`, `trv`, and Cargo-installed `rustlings` are not reproduced
by this flake; they are migration leftovers, not additional preferred managers.
Semble uses pinned uvx execution, not a standalone install; see [Semble and OpenCode](#semble-and-opencode).
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
configuration using Home Manager's dry-run-aware `run` helper. Dry runs do not
install tools, and no extra `reshim` is needed after `mise install`. It does not
upgrade already-installed tools; use `mise upgrade` for that. Their versions are
independent of the pinned mise executable (currently 2026.5.12).
Existing external mise installations are retained but are no longer the shell's
default. Update mise itself through Nix, not `mise self-update`.

The shared shell replaces Zinit with Nix-packaged Powerlevel10k, zsh-completions,
fzf-tab, autosuggestions, and syntax highlighting. Existing Zinit files are left on
disk but are no longer sourced or updated at startup. Fzf and zoxide integration
each have one owner in Home Manager, as does mise activation. Nix supplies mise's
completion; uv/gh completion generation remains explicit for their active executables.

### Semble and OpenCode

Mise installs OpenCode and uv at `latest`; OpenCode self-updates remain disabled
so `mise upgrade` owns updates. `programs.opencode.package = pkgs.emptyDirectory`
works around a pinned Home Manager warning bug with `package = null`. The empty
package installs no binary; Home Manager manages only configuration, instructions,
and the subagent in `modules/terminal/opencode/`.

MCP directly runs `uvx --from 'semble[mcp]==0.5.6' semble`. CLI fallback uses
the same prefix, for example:

```sh
uvx --from 'semble[mcp]==0.5.6' semble search "authentication flow" .
```

Launch OpenCode from a mise-enabled Zsh so `uvx` is on its inherited PATH.
The previous launcher provided absolute uv/Python paths for noninteractive MCP
startup and a process-local C++ library path for NumPy under Nix Python. That
addressed runtime discovery but was unnecessary custom packaging for this setup;
the direct command no longer forces Nix Python. Initial execution needs network
access and resolves Python dependencies into uv's cache, not a fully locked/offline
environment. Model/indexing behavior still needs runtime verification.
Do not run `semble install`, `uv tool install`, or `uv tool upgrade semble` for
this integration. Update the pin in the MCP config and both instruction templates
together. Existing standalone copies are neither used by MCP nor deleted here.

Legacy `opencode.jsonc` is never deleted automatically: activation stops if it
exists, including a dangling link. Review and back it up outside the config
directory, merging desired settings into Nix first. Home Manager's normal conflict
checks protect unmanaged `AGENTS.md` and agent files. After a future activation,
quit and restart OpenCode to load the new configuration.

The laptop's functions, aliases, and history exclusions are the shared baseline.
`ask` uses the laptop's model list/default and preserves separate CLI arguments.
Its pipeline now propagates OpenCode failures. Model availability is provider-side
and has not been tested with real requests. The mini's Powerlevel10k configuration
was copied unchanged; the laptop's prompt configuration was not available to compare.

### Ghostty ownership

Home Manager installs and updates Ghostty through `pkgs.ghostty-bin` on Darwin
and `pkgs.ghostty` on Linux, and owns
`~/.config/ghostty/config` through `modules/programs/ghostty.nix`. Edit the Nix
module and run `just switch-hm`; do not edit the generated config. Do not install a
second Homebrew copy or create a separate file-backed Ghostty configuration on this
Mac. Avoid a second config under
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

Home Manager owns `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, and `~/.p10k.zsh` on both hosts.
Edit the repository and switch, rather than editing the generated symlinks. Avoid
running `p10k configure` against the immutable managed file; make prompt changes
in `config/p10k.zsh`. Mini's login shell remains `/bin/zsh`; Uno's is already
`/usr/bin/zsh`, registered in `/etc/shells`. Home Manager installs Nix Zsh but
does not change the login shell. Both load the managed home configuration; see
[Arch setup](docs/linux-setup.md#login-shell) for an optional Nix login-shell handoff.

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

## Linux: Arch Home Manager

`homeConfigurations."ayrton@uno"` targets `/home/ayrton` on `x86_64-linux`.
Home Manager owns shared terminal tools, native desktop configuration, and the
declared user-space desktop packages. Arch still owns the system/session stack.
Follow [Arch setup](docs/linux-setup.md) for bootstrap, build review,
activation, and recovery. The source-only cleanup is complete; desktop text
sources are consolidated under `config/`.

`just` selects the account with `whoami`, and the hostname with
`hostnamectl --static` on Linux or `scutil --get LocalHostName` on macOS.
No `hostname` executable is needed. Darwin recipes remain macOS-only.

### Ownership

- `hosts/uno/home.nix`: account, state version, and explicit terminal/Ghostty/desktop imports.
- `modules/terminal`: shared Zsh, Powerlevel10k, tmux, mise, OpenCode, and CLI tools.
- `modules/programs/ghostty.nix`: shared Ghostty settings and font.
- `modules/linux/desktop.nix`: native Hyprland Lua, Hypridle, Hyprlock, Hyprpaper,
  Waybar, Rofi, Wlogout, fontconfig, wallpaper assets, and wallpaper script links.
- Nix: Hyprland, Hyprshot, Ghostty, Rofi, Wlogout, Dolphin, Blueman, nm-applet, Hypridle, Hyprpaper,
  brightnessctl, playerctl, pavucontrol, wpctl, script dependencies, fonts and icons.
- Pacman/AUR: Waybar, Hyprlock/PAM, Zen, GPU/ROCm drivers and system services.
- Wallpaper script: writable `~/.config/rofi/background.rasi` and cache index;
  Home Manager only seeds the background file when absent.

Native desktop text sources live in `config/hypr`, `config/waybar`, `config/rofi`,
`config/wlogout`, and `config/fontconfig`; the wallpaper script is
`scripts/change-wallpaper.sh`. Wallpaper and Wlogout icon binaries remain in their
existing asset directories.

### Desktop Packages

Prefer the packages declared in `modules/linux/desktop.nix`, not a second broad
`yay -S` list. Keep existing Arch copies for recovery until the Nix generation is
validated. Home Manager has been activated on Uno, but it neither uninstalls Arch
packages nor replaces the running graphical session.

Pinned Hyprland 0.55.4 builds with Lua 5.5 and passed `Hyprland --verify-config`
against the complete `config/hypr/hyprland.lua`. It and Hyprshot 1.3.0 are now
declared in Uno's Nix packages. Hyprshot's wrapper uses the matching Nix `hyprctl`;
its script only queries JSON monitors/clients/active workspace/window, not legacy
dispatch commands. This removes the previous unsupported version-coupling claim.

Waybar 0.15.0 is available but its `src/modules/hyprland/workspace.cpp` sends
`dispatch workspace ...` (and legacy special-workspace variants) for built-in
workspace clicks. Hyprland 0.55.4's `src/debug/HyprCtl.cpp:1107` interprets dispatch
as Lua `hl.dispatch(...)`; those legacy strings fail. Keep the installed
`waybar-git 0.15.0.r1004.g6d60c8e-1` until a Lua-aware Nix version is pinned,
rather than patching the package here. Its installed source translates built-in
clicks to Lua. Explicit scroll commands and Hypridle DPMS commands now use Lua
dispatcher expressions as well.
Hyprlock stays with Arch's PAM integration; Zen has no package in this pinned
nixpkgs set. Installing Hyprland in a home profile does not select a display-manager
session or replace Arch's running 0.56.2 compositor. Review session discovery and
test a fresh session before handoff; existing Arch packages remain installed.

Uno now imports `modules/linux/session.nix`: pinned nixGL Mesa using the same
nixpkgs, a Nix session launcher, and separate Nix/explicit Arch-fallback desktop
entries. Hardware-rendered EGL/GLX checks passed on its RX 9070; a fresh login and
full desktop testing remain necessary. Arch kernel/GPU/ROCm packages are untouched,
and macOS does not import this integration. See [session handoff](docs/linux-setup.md#session-handoff)
for the administrator installation commands and recovery procedure.
