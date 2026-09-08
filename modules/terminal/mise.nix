{ lib, config, ... }:

{
  programs.mise = {
    enable = lib.mkDefault true;
    enableZshIntegration = true;
    globalConfig.tools = {
      uv = "latest";
      opencode = "latest";
      node = "latest";
      pnpm = "latest";
      rust = "latest";
    };
  };

  # Home Manager writes the global config; mise fetches missing configured tools.
  home.activation.miseInstall = lib.mkIf config.programs.mise.enable (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${lib.getExe config.programs.mise.package} install --yes --cd /
    ''
  );
}
