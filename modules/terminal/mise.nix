{ lib, config, ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig.tools = {
      node = "latest";
      pnpm = "latest";
      rust = "latest";
      opentofu = "latest";
      terragrunt = "latest";
      opencode = "latest";
      gh = "latest";
      uv = "latest";
      ffmpeg = "latest";
      # Upstream publishes binary builds as b-prefixed prereleases.
      "github:ggml-org/llama.cpp" = {
        version = "latest";
        version_prefix = "b";
        prerelease = true;
      };
    };
  };

  # Home Manager writes the global config; mise fetches missing configured tools.
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${config.home.profileDirectory}/bin/mise install --yes --cd /
  '';
}
