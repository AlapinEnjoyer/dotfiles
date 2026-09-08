# Arch Setup: uno

The standalone Home Manager target is `ayrton@uno`, with system `x86_64-linux`
and home `/home/ayrton`. This is not NixOS: Arch continues to own the system and
session integration. Nix is the preferred package owner for user-space apps;
mise is the intended alternate for selected runtimes. Home Manager has been
activated on Uno, but activation does not replace the running compositor.
Use the separate session entries below to test the Nix desktop before removing
any Arch packages.

## Scope

| Owner | State |
| --- | --- |
| Home Manager | Shared terminal, Nix Ghostty, user-space desktop packages, native desktop config links, fonts/icons, wallpaper assets/script, CLI tools, and a Nix session launcher with nixGL |
| Pacman/AUR | Waybar, Hyprlock/PAM, Zen, GPU/ROCm drivers and system packages |
| mise | OpenCode, uv, Node, pnpm, Rust, and upstream llama.cpp prerelease binaries, all at `latest` |
| Arch/systemd | Login/session setup, NetworkManager, Bluetooth, audio, power management |
| Wallpaper script | `~/.cache/wallpaper-index` and regular writable `~/.config/rofi/background.rasi` |
| Nix installer | Nix daemon, store, and shell integration |

`hosts/uno/home.nix` imports the shared terminal and Ghostty modules plus its Linux
desktop module. The terminal module owns Zsh, Powerlevel10k, tmux, mise, OpenCode,
and shared CLI tools on both hosts. Ghostty is independently selected by each host,
not imported by the CLI terminal bundle. Only Mini imports `zsh/homebrew.nix`; Homebrew
integration is not part of the shared terminal module. Ghostty defaults to
`pkgs.ghostty` on Linux and `pkgs.ghostty-bin` on Darwin; there is no `/usr/bin`
adapter. Settings remain shared, with Cmd-Backspace restored only on Darwin.
Neovim is in shared `home.packages`, with aliases in Zsh and no managed `init.lua`.
OpenCode and uv are mise-owned on both hosts. Semble's direct pinned uvx command is
described in the [README](../README.md#semble-and-opencode).

## Prerequisites

Confirm the target without installing a `hostname` utility:

```sh
whoami                 # ayrton
hostnamectl --static   # uno
uname -m               # x86_64
```

Install Nix using a supported multi-user installer, following its current Linux
instructions, for example the [official Nix installation guide](https://nixos.org/download/).
Review the installer before running it. Open a new terminal and check `nix --version`
and `nix store ping --extra-experimental-features nix-command`. This repository
does not install Nix, change its daemon configuration, or change the login shell.
The Uno Home Manager configuration writes its user-level Nix settings after the
first activation. Bootstrap commands below pass `nix-command flakes` explicitly;
subsequent commands do not need the flags.

Pinned Hyprland 0.55.4 supports Lua and passes the complete config verification;
Hyprshot 1.3.0 uses compatible JSON queries. Both are declared in Nix. Waybar
0.15.0's built-in workspace clicks still use legacy dispatch syntax rejected by
Lua Hyprland, so retain Arch's git build; see the
[source-level findings](../README.md#desktop-packages). Review AUR PKGBUILDs and
keep working package versions until the migration is validated.
If bootstrapping yay, install `base-devel` and `git` with pacman, clone
`https://aur.archlinux.org/yay.git`, review it, then run `makepkg -si` there as
the normal user, not root.

`modules/linux/desktop.nix` provisions Hyprland, Hyprshot, Rofi, Wlogout, Dolphin, Blueman, nm-applet,
Hypridle, Hyprpaper, brightnessctl, playerctl, pavucontrol, wpctl, Bash, coreutils,
findutils, grep, sed, curl, procps, and the referenced fonts/icon theme through Nix.
It does not enable their services or add duplicate autostart entries. The pinned
Hypridle is 0.1.7 versus Arch's installed 0.1.8; test idle behavior before handoff.

Also verify the system dependencies of the native configs/scripts:

- PipeWire/WirePlumber services; installing the `wpctl` client does not start them.
- A working polkit authentication agent, graphics drivers and Wayland session.
- NetworkManager and Bluetooth services as appropriate for this machine.
- Arch Waybar, Hyprlock and Zen for the unchanged bindings.

Home Manager does not enable these system services or add a second copy of the
Hyprland autostart processes. Test Hyprlock authentication with Arch's PAM setup
before relying on idle locking. Suspend/hibernate support remains system-owned.

### Non-NixOS Graphics

Uno imports `modules/linux/session.nix`, using pinned nixGL Mesa built with the
same nixpkgs input as its applications. Only 64-bit Mesa is included; there is no
NVIDIA autodetection, Intel media driver, kernel driver, or ROCm migration. Arch's
GPU packages remain installed and unchanged. The wrapper supplies process-local
graphics paths, not global shell `LD_LIBRARY_PATH` settings. This is Uno-specific;
the Mac imports neither this module nor nixGL.

The wrapper has passed Wayland/EGL and Xwayland/GLX hardware-rendering checks on
Uno's Radeon RX 9070 with Nix Mesa 26.1.8. An all-device EGL probe also reported an
access warning and enumerated a software renderer; the selected Wayland and GLX
renderers were the AMD GPU. This does not prove a fresh DRM/login session, locking,
suspend, portals, Qt/GTK integration, or Vulkan workloads. Vulkan is not configured
by this OpenGL wrapper. Arch Waybar and Hyprlock pass `--version` under the wrapper,
but their full runtime behavior still needs testing with inherited graphics paths.

### Session Handoff

Home Manager creates `~/.local/bin/start-hyprland-nix` and one desktop entry under
`~/.local/share/wayland-sessions`. The Nix launcher sources Home Manager variables,
sets profile-first `PATH` and `XDG_DATA_DIRS`, and pins the watchdog's compositor
path. Hyprland's watchdog automatically invokes the supplied `nixGL` wrapper.
For Nix GPU apps launched from another session, use `nixGL ghostty` explicitly.

SDDM only scans system session directories here. After building and activating
Home Manager, install the reviewed entry as root (this name must not
already exist; inspect it instead if either preflight fails):

```sh
test ! -e /usr/local/share/wayland-sessions/hyprland-nix.desktop && \
test ! -L /usr/local/share/wayland-sessions/hyprland-nix.desktop && \
sudo install -D -m 644 "$HOME/.local/share/wayland-sessions/hyprland-nix.desktop" \
  /usr/local/share/wayland-sessions/hyprland-nix.desktop
```

This is a root-owned copy, not a root service executing user-controlled code.
The Nix entry starts the user-owned launcher as the logged-in user. Future launcher
changes follow Home Manager automatically; desktop-entry changes need recopying.
No packaged session entry is overwritten. Do not restart SDDM inside your session.
Save work, log out normally, and select **Hyprland (Nix)**. If the new entry does
not appear, reboot after saving work. The entry uses the Home Manager-managed config.

After logging in, verify the running executable rather than only `command -v`:

```sh
readlink /proc/$(pgrep -u "$USER" -x Hyprland)/exe
hyprctl version
hyprctl configerrors
```

The Nix session should show a `/nix/store/...hyprland.../bin/.Hyprland-wrapped`
executable and version 0.55.4 at the current pin. Inspect desktop-child executables
as well; a Nix-first terminal alone does not prove autostart migrated. On failure,
use a TTY (`Ctrl+Alt+F3`) and inspect `~/.local/share/sddm/wayland-session.log`,
roll back with `home-manager generations`, or restore a Timeshift snapshot.
Duplicate Arch desktop packages were removed once the Nix session proved stable;
only Waybar, Hyprlock, Zen, VS Code, SDDM, fonts, portals, XWayland, GPU/ROCm,
and system services remain Arch-managed.

## Build First

Work from `/home/ayrton/dotfiles`. Review changes and build the current sources
before any future activation:

```sh
nix --extra-experimental-features 'nix-command flakes' build \
  'path:.#homeConfigurations."ayrton@uno".activationPackage' --print-build-logs
```

`path:.` includes the new, unstaged files without requiring staging or a commit.
Review the entire source tree for secrets first: path flakes can include ignored
and untracked files in the store. Once the new files are tracked, use the ordinary
`.#homeConfigurations."ayrton@uno".activationPackage` reference. Do not update
`flake.lock` or `home.stateVersion` merely to activate the configuration.

Building creates `result` but does not activate it. Inspect the links under
`result/home-files` and the generated activation script. If Nix cannot evaluate
or build, leave the live configuration unchanged.

## Source Layout

Desktop text sources are consolidated under `config/`: Hyprland and its `conf/`
fragments are in `config/hypr`; Waybar, Rofi, Wlogout, and fontconfig
are in their matching subdirectories. `scripts/change-wallpaper.sh` is the
wallpaper script source. `backgrounds/.config/backgrounds` and
`wlogout/.config/wlogout/icons` intentionally retain binary assets and are linked
separately by `modules/linux/desktop.nix`.

Home Manager links Rofi's static config and colors. It seeds the background only
if neither a file nor a symlink exists and never resets it on subsequent switches.
The wallpaper script continues to write it and the cache index, not any
store-managed file. It changes Hyprpaper via IPC, not by rewriting its config.
Do not manually edit other managed destination files; edit sources and rebuild.

## Review and Activate

Before any future activation, preview the already-built generation:

```sh
DRY_RUN=1 ./result/activate
```

Check for conflicts and review the intended shell, mise, OpenCode, and desktop
package ownership changes. No system service migration is declared. Mise's
install hook respects dry runs. Legacy OpenCode JSONC blocks activation instead
of being deleted; back it up and reconcile it explicitly. Other unmanaged files
are protected by Home Manager's normal conflict checks. A dry run cannot prove runtime behavior.
Only when ready, activate as `ayrton`, **without sudo**:

```sh
./result/activate
```

The existing Nix installer shell integration must expose the user profile's
`bin` directory. If `home-manager` is not found in a new terminal, inspect that
integration and the profile location before changing PATH. Uno now generates the
shared Zsh startup files; back up and reconcile pre-existing files before handoff.
Do not source the legacy root `.zshrc`, Mac-only Homebrew integration, or add
duplicate mise initialization. The account's login shell is not changed.
Quit and restart OpenCode from the new mise-enabled shell after activation.

### Login Shell

`getent passwd ayrton` currently reports `/usr/bin/zsh`, already listed in
`/etc/shells`. Zsh is already the primary login shell; no `chsh` is required.
Home Manager enables Zsh and installs Nix Zsh 5.9.1 alongside the existing Arch
5.9.2, without changing `/etc` or the account. Both load the managed startup files.

If you explicitly want the Nix binary as the login shell after activation, first
evaluate its stable profile path and verify the executable:

```sh
profile=$(nix eval --raw 'path:.#homeConfigurations."ayrton@uno".config.home.profileDirectory')
test -x "$profile/bin/zsh"
"$profile/bin/zsh" -ic 'print -r -- $ZSH_VERSION'
```

That exact `$profile/bin/zsh` path is not currently registered in `/etc/shells`.
An administrator must add the expanded absolute path as a separate line using
`sudoedit /etc/shells` before the normal-user command `chsh -s "$profile/bin/zsh"`.
Do not register a generation-specific `/nix/store` path. Keep the profile installed
and a recovery terminal open, then log out/in and verify with `getent passwd ayrton`.
None of these registration or login-shell changes is performed by this refactor.

After the files are tracked and Nix features enabled, normal commands are:

```sh
just build-hm
just switch-hm-dry-run
just switch-hm
home-manager generations
```

Until then, use the explicit `path:.` build above rather than the Git-backed Just
recipes. `just` derives `ayrton@uno` using `whoami` and `hostnamectl --static` on
Linux; macOS still uses `scutil --get LocalHostName`. If systemd's hostname service
is unavailable, override explicitly with `just hostname=uno build-hm`.
Darwin recipes remain macOS-only. `test-zsh` is valid on either host after the
shared shell is active; it tests the active shell, not a merely built generation.

## Validation and Recovery

Run `bash tests/linux-desktop-smoke.sh` for an isolated wallpaper write test.
Run `bash tests/nix-refactor-smoke.sh` (Nix and jq required) for both-host package,
binding, override, mise dry-run, and non-destructive OpenCode conflict checks.
This checks shell/Lua syntax and writable wallpaper state, not GUI parsing.
An attempted `rofi -rasi-validate` check on this machine crashed with an isolated
HOME and timed out against the Rofi config; Rofi validation remains a live
session check, not a passing automated test.
After activation, check all of the following in the actual desktop session:

- Hyprland loads Lua config without errors; bindings and monitor/input settings work.
- Waybar workspace clicks and scroll work with the installed Lua IPC version.
  The retained Arch git build translates built-in clicks to Lua; explicit scroll
  commands and Hypridle DPMS commands now use native Lua dispatcher expressions.
- Cycle wallpapers with Super+Shift+W, then open Rofi; confirm both backgrounds
  change and `~/.config/rofi/background.rasi` is a writable regular file.
- Ghostty font/theme, Wlogout icons, audio controls, Bluetooth/network tray and
  weather work. Weather requires external network access.
- Hyprlock unlocks correctly, Hypridle runs once, and suspend/resume restores DPMS.
- Screen sharing/portals, Xwayland apps and D-Bus-launched apps work. The launcher
  does not replace Arch services or pre-existing systemd-user activation environments.

Existing host-specific settings are preserved, not validated by a Nix build:
Waybar uses `/sys/class/hwmon/hwmon3/temp1_input`; verify that sensor on uno.
Hyprlock now references the existing `griffith.jpg` wallpaper.

### Package Cleanup

Home Manager does not uninstall pacman/AUR packages. `yay -Qt` includes explicitly
installed applications, not just orphans; never remove its complete output.
After both desktop sessions and the Nix applications are tested, review duplicated
packages individually with `pacman -Qi NAME` and preview a removal transaction.
Retain Waybar git, Hyprlock/PAM, Zen, VS Code, the system login shell, SDDM, GPU/ROCm,
network/audio/Bluetooth services and other system packages. `ffmpeg4.4` is a legacy
library version, not automatically replaceable by Nix ffmpeg. No package removal
is performed by these modules or the session installation commands.

For later regressions, inspect `home-manager generations` and activate a known
good retained generation. Rolling back does **not** restore writable wallpaper
state; retain regular-file backups until the migration is stable. Keep generations
and Arch packages until then; do not run GC yet.

The source-only cleanup is complete. Update module declarations and source paths
together for future moves, then rebuild before activating. Keep wallpaper and icon
binaries in their existing asset directories unless a binary-safe migration is
explicitly planned.
