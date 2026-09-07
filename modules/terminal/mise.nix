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
    };
  };
}
