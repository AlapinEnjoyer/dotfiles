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
      # Upstream publishes binary builds as b-prefixed prereleases.
      "github:ggml-org/llama.cpp" = {
        version = "latest";
        version_prefix = "b";
        prerelease = true;
      };
    };
  };

  # Home Manager writes the global config; mise fetches missing configured tools.
  home.activation.miseInstall = lib.mkIf config.programs.mise.enable (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${lib.getExe config.programs.mise.package} install --yes --cd /
    ''
  );
}
