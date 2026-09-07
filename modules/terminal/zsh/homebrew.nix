{ lib, pkgs, ... }:

let
  brewPrefix = if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local";
  brewLibrary = if pkgs.stdenv.hostPlatform.isAarch64 then "${brewPrefix}/Library" else "${brewPrefix}/Homebrew/Library";
in
{
  programs.zsh.profileExtra = ''
    if [[ -x ${brewPrefix}/bin/brew ]]; then
      eval "$(${brewPrefix}/bin/brew shellenv)"
    fi
  '';

  programs.zsh.initContent = lib.mkOrder 550 ''
    () {
      local brewCode=${brewLibrary}/Homebrew
      local brewCompletions="''${brewCode:A:h:h}/completions/zsh"
      # nix-homebrew keeps _brew in the store; migration can leave a dangling
      # prefix link. Load the real definition first so compinit skips that link.
      if [[ -r "$brewCompletions/_brew" ]]; then
        fpath=("$brewCompletions" $fpath)
      fi
    }
    if [[ -d ${brewPrefix}/share/zsh/site-functions ]]; then
      fpath+=(${brewPrefix}/share/zsh/site-functions)
    fi
  '';
}
