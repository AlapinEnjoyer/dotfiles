{ lib, pkgs, ... }:

{
  programs.opencode = {
    enable = true;
    # Keeps mise as the executable owner while satisfying Home Manager's package check.
    package = pkgs.emptyDirectory;
    context = ./AGENTS.md;
    agents.semble-search = ./agents/semble-search.md;
    settings = {
      username = "Pesto";
      model = "openai/gpt-5.6-luna";
      small_model = "opencode/mimo-v2.5-free";

      compaction.auto = false;

      permission.bash = {
        "*" = "allow";
        git = "allow";
        "git *" = "allow";
        "git commit*" = "ask";
        "git push*" = "ask";
        "git rebase*" = "ask";
        "git reset*" = "ask";
        "git checkout*" = "ask";
        rm = "ask";
        "rm *" = "ask";
        "python *" = "deny";
        "python3 *" = "deny";
        "pip *" = "deny";
        "pip3 *" = "deny";
        "npm *" = "ask";
      };

      mcp.semble = {
        command = [
          "uvx"
          "--from"
          "semble[mcp]==0.5.6"
          "semble"
        ];
        type = "local";
        enabled = true;
      };

      provider = {
        github-copilot.whitelist = [
          "gpt-5.5"
          "gpt-5.4"
          "gpt-5.4-mini"
          "claude-opus-4.6"
          "claude-sonnet-4.6"
          "gpt-5.6-luna"
          "gpt-5.6-terra"
          "gpt-5.6-sol"
        ];
        google.whitelist = [
          "gemma-4-26b-it"
          "gemma-4-31b-it"
          "gemini-3.1-flash-lite-preview"
          "gemini-flash-lite-latest"
        ];
        "llama.cpp" = {
          npm = "@ai-sdk/openai-compatible";
          name = "llama.cpp";
          options.baseURL = "http://localhost:11434/v1";
          models.local.name = "local";
        };
        openrouter = {
          whitelist = [
            "deepseek/deepseek-v4-flash-0731"
            "xiaomi/mimo-v2.5"
            "xiaomi/mimo-v2.5-pro"
          ];
          models = {
            "xiaomi/mimo-v2.5" = {
              name = "Xiaomi MiMo V2.5";
              limit = {
                context = 1000000;
                output = 131072;
              };
              options.provider = {
                order = [ "xiaomi/fp8" ];
                allow_fallbacks = false;
              };
            };
            "xiaomi/mimo-v2.5-pro" = {
              name = "Xiaomi MiMo V2.5 Pro";
              limit = {
                context = 1000000;
                output = 131072;
              };
              options.provider = {
                order = [ "xiaomi/fp8" ];
                allow_fallbacks = false;
              };
            };
            "deepseek/deepseek-v4-flash-0731" = {
              name = "DeepSeek V4 Flash 0731";
              limit = {
                context = 1048576;
                output = 262144;
              };
              options.provider = {
                order = [ "streamlake/fp8" ];
                allow_fallbacks = false;
              };
            };
          };
        };
      };
    };
  };

  home.sessionVariables.OPENCODE_ENABLE_EXA = "1";

  home.activation.removeLegacyOpencodeFiles = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f \
      "$HOME/.config/opencode/opencode.jsonc" \
      "$HOME/.config/opencode/AGENTS.md" \
      "$HOME/.config/opencode/agents/semble-search.md"
  '';
}
