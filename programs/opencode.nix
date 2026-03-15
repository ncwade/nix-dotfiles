{ pkgs, ... }:
let
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    enabled_providers = [ "openai" ];
    model = "openai/gpt-5.3-codex";
    small_model = "openai/gpt-5-nano";
    provider = {
      openai = {
        options = {
          timeout = 600000;
        };
        models = {
          "gpt-5.4" = {
            variants = {
              xhigh = {
                reasoningEffort = "xhigh";
                textVerbosity = "low";
                reasoningSummary = "auto";
                include = [ "reasoning.encrypted_content" ];
              };
            };
          };
          "gpt-5.3-codex" = {
            variants = {
              high = {
                reasoningEffort = "high";
                textVerbosity = "low";
                reasoningSummary = "auto";
                include = [ "reasoning.encrypted_content" ];
              };
              medium = {
                reasoningEffort = "medium";
                textVerbosity = "low";
                reasoningSummary = "auto";
                include = [ "reasoning.encrypted_content" ];
              };
            };
          };
          "gpt-5.3-codex-spark" = {
            variants = {
              low = {
                reasoningEffort = "low";
                textVerbosity = "low";
                reasoningSummary = "auto";
                include = [ "reasoning.encrypted_content" ];
              };
            };
          };
        };
      };
    };
    agent = {
      build = {
        model = "openai/gpt-5.3-codex";
        variant = "high";
      };
      plan = {
        model = "openai/gpt-5.4";
        variant = "xhigh";
      };
      general = {
        model = "openai/gpt-5.3-codex";
        variant = "medium";
      };
      explore = {
        model = "openai/gpt-5.3-codex-spark";
        variant = "low";
      };
    };
  };

  opencodeTuiConfig = {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "ghostty";
  };

  opencodeJson = (pkgs.formats.json { }).generate "opencode-config" opencodeConfig;
  opencodeTuiJson = (pkgs.formats.json { }).generate "opencode-tui-config" opencodeTuiConfig;
in
{
  xdg.configFile."opencode/opencode.json".source = opencodeJson;
  xdg.configFile."opencode/tui.json".source = opencodeTuiJson;
  xdg.configFile."opencode/themes/ghostty.json".source = ./opencode-ghostty-theme.json;
}
