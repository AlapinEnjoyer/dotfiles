{ lib, pkgs, ... }:

let
  brewPrefix = if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local";
in
{
  programs.zsh.profileExtra = ''
    if [[ -x ${brewPrefix}/bin/brew ]]; then
      eval "$(${brewPrefix}/bin/brew shellenv)"
    fi
  '';

  programs.zsh.initContent = lib.mkOrder 550 ''
    if [[ -d ${brewPrefix}/share/zsh/site-functions ]]; then
      fpath+=(${brewPrefix}/share/zsh/site-functions)
    fi
  '';
}
