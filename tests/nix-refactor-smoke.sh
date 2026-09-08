#!/usr/bin/env bash
# Evaluate both hosts and exercise only isolated hooks, never a full activation.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export REFACTOR_REPO="$repo" REFACTOR_HOME="$scratch/home"
mkdir -p "$REFACTOR_HOME/.config/opencode/agents"

checks=$(nix eval --impure --json --expr '
  let
    f = builtins.getFlake ("path:" + builtins.getEnv "REFACTOR_REPO");
    lib = f.inputs.nixpkgs.lib;
    uno = f.homeConfigurations."ayrton@uno";
    mini = f.homeConfigurations."ayrton@mini";
    cliOnly = f.inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = uno.pkgs;
      modules = [
        (f.outPath + "/modules/terminal")
        {
          home.username = "smoke";
          home.homeDirectory = "/home/smoke";
          home.stateVersion = "26.05";
        }
      ];
    };
    shared = h:
      let c = h.config; p = h.pkgs; in
      assert c.programs.zsh.enable && c.programs.mise.enable;
      assert c.programs.opencode.package == p.emptyDirectory;
      assert !(builtins.elem p.opencode c.home.packages);
      assert !(builtins.elem p.uv c.home.packages);
      assert c.programs.opencode.settings.autoupdate == false;
      assert c.programs.zsh.shellAliases.vi == "nvim";
      assert c.programs.zsh.shellAliases.v == "nvim";
      assert builtins.elem p.neovim c.home.packages;
      assert builtins.elem p.zsh c.home.packages;
      assert builtins.all (pkg: builtins.elem pkg c.home.packages) [ p.gh p.ffmpeg p.opentofu p.terragrunt ];
      assert builtins.elem p.viu c.home.packages;
      assert builtins.all (pkg: builtins.elem pkg c.home.packages) [ p.tealdeer p.wget ];
      assert !(c.xdg.configFile ? "nvim/init.lua");
      assert builtins.attrNames c.programs.mise.globalConfig.tools == [
        "github:ggml-org/llama.cpp" "node" "opencode" "pnpm" "rust" "uv"
      ];
      assert c.programs.mise.globalConfig.tools.uv == "latest";
      assert c.programs.mise.globalConfig.tools.opencode == "latest";
      assert !(c.home.activation ? removeLegacyOpencodeFiles);
      assert lib.hasInfix "run /nix/store/" c.home.activation.miseInstall.data;
      assert !(lib.hasInfix "reshim" c.home.activation.miseInstall.data);
      assert c.programs.opencode.settings.mcp.semble.command == [
        "uvx" "--from" "semble[mcp]==0.5.6" "semble"
      ];
      true;
    isolated = uno.extendModules {
      modules = [{ home.homeDirectory = lib.mkForce (builtins.getEnv "REFACTOR_HOME"); }];
    };
    overridden = uno.extendModules {
      modules = [{
        programs.ghostty.package = uno.pkgs.hello;
        programs.ghostty.settings.font-size = 14;
        programs.mise.enable = false;
        programs.opencode.enable = false;
      }];
    };
  in
  assert shared uno && shared mini && shared cliOnly;
  assert builtins.elem uno.pkgs.hyprland uno.config.home.packages;
  assert builtins.elem uno.pkgs.hyprshot uno.config.home.packages;
  assert builtins.elem uno.pkgs.blueman uno.config.dbus.packages;
  assert uno.config.xdg.configFile ? "systemd/user/blueman-manager.service";
  assert builtins.elem uno.pkgs.fastfetch uno.config.home.packages;
  assert builtins.elem uno.pkgs.nvtopPackages.amd uno.config.home.packages;
  assert uno.config.home.sessionVariables.ROCM_PATH == "/opt/rocm";
  assert !(builtins.elem uno.pkgs.waybar uno.config.home.packages);
  assert builtins.any (pkg: (pkg.name or "") == "nixGL") uno.config.home.packages;
  assert !(mini.config.home.file ? ".local/bin/start-hyprland-nix");
  assert lib.hasInfix (builtins.unsafeDiscardStringContext "--path ${uno.pkgs.hyprland}/bin/Hyprland") uno.config.home.file.".local/bin/start-hyprland-nix".text;
  assert lib.hasInfix "${uno.config.home.profileDirectory}/bin:$HOME/.local/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin" uno.config.home.file.".local/bin/start-hyprland-nix".text;
  assert builtins.elem "/nix/var/nix/profiles/default/bin" uno.config.home.sessionPath;
  assert lib.hasInfix "${uno.config.home.profileDirectory}/share:/usr/local/share:/usr/share" uno.config.home.file.".local/bin/start-hyprland-nix".text;
  assert lib.hasInfix "Exec=/home/ayrton/.local/bin/start-hyprland-nix" uno.config.xdg.dataFile."wayland-sessions/hyprland-nix.desktop".text;
  assert lib.hasInfix "TryExec=/usr/bin/true" uno.config.xdg.dataFile."wayland-sessions/hyprland-nix.desktop".text;
  assert !cliOnly.config.programs.ghostty.enable;
  assert uno.config.programs.ghostty.enable && mini.config.programs.ghostty.enable;
  assert uno.config.programs.ghostty.package == uno.pkgs.ghostty;
  assert mini.config.programs.ghostty.package == mini.pkgs.ghostty-bin;
  assert builtins.elem "cmd+backspace=text:\\x15" mini.config.programs.ghostty.settings.keybind;
  assert !(builtins.elem "cmd+backspace=text:\\x15" uno.config.programs.ghostty.settings.keybind);
  assert overridden.config.programs.ghostty.package == uno.pkgs.hello;
  assert overridden.config.programs.ghostty.settings.font-size == [ 14 ];
  assert !(overridden.config.home.activation ? miseInstall);
  assert !(overridden.config.home.activation ? checkLegacyOpencodeConfig);
  {
    mise = isolated.config.home.activation.miseInstall.data;
    legacy = isolated.config.home.activation.checkLegacyOpencodeConfig.data;
  }
')

mise_hook=$(jq -r .mise <<< "$checks")
legacy_hook=$(jq -r .legacy <<< "$checks")

# Home Manager provides run; reject any attempt to bypass it in a dry run.
run() {
  test "${DRY_RUN:-}" = 1
  [[ "$1" == /nix/store/*/bin/mise ]]
  shift
  test "$*" = 'install --yes --cd /'
  called=1
}
called=0
DRY_RUN=1 eval "$mise_hook"
test "$called" = 1

legacy="$REFACTOR_HOME/.config/opencode/opencode.jsonc"
agents="$REFACTOR_HOME/.config/opencode/AGENTS.md"
printf 'user instructions\n' > "$agents"
printf 'user agent\n' > "$REFACTOR_HOME/.config/opencode/agents/semble-search.md"
printf 'user config\n' > "$legacy"
before=$(sha256sum "$agents" "$legacy" "$REFACTOR_HOME/.config/opencode/agents/semble-search.md")
for dry in 1 ''; do
  if (export DRY_RUN="$dry"; eval "$legacy_hook"); then
    printf 'Legacy config should block activation\n' >&2
    exit 1
  fi
done
test "$before" = "$(sha256sum "$agents" "$legacy" "$REFACTOR_HOME/.config/opencode/agents/semble-search.md")"
rm -- "$legacy"
ln -s missing-target "$legacy"
if (eval "$legacy_hook"); then
  printf 'Dangling legacy link should block activation\n' >&2
  exit 1
fi
test -L "$legacy"
rm -- "$legacy"
(eval "$legacy_hook")
test -f "$agents"
printf 'Nix refactor smoke checks passed (both hosts, overrides, dry-run and conflict safety).\n'
