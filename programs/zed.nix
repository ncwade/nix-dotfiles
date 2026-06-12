{ ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "html"
      "catppuccin"
      "toml"
      "nix"
      "fish"
      "catppuccin-icons"
      "astro"
    ];
    userSettings = {
      disable_ai = true;
      colorize_brackets = true;
      theme = {
        mode = "system";
        dark = "Catppuccin Mocha";
        light = "One Light";
      };
      agent = {
        default_model = {
          provider = "copilot_chat";
          model = "gpt-5";
        };
        model_parameters = [ ];
        play_sound_when_agent_done = true;
      };
      agent_servers = {
        "OpenCode (Local)" = {
          type = "custom";
          command = "/Users/ncwade/src/github.com/anomalyco/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode";
          args = [ "acp" ];
        };
        OpenCode = {
          type = "custom";
          command = "opencode";
          args = [ "acp" ];
        };
      };
      edit_predictions = {
        provider = "copilot";
        mode = "eager";
      };
      icon_theme = "Catppuccin Mocha";
      ui_font_size = 14;
      buffer_font_family = "JetBrainsMono Nerd Font Mono";
      terminal = {
        shell = {
          program = "fish";
        };
        line_height = "standard";
      };
      ssh_connections = [
        {
          host = "corp-ubuntu-nix";
          username = "ncwade";
          nickname = "Corporate Ubuntu VM";
          upload_binary_over_ssh = true;
        }
      ];
    };
    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          "shift shift" = "file_finder::Toggle";
        };
      }
      {
        context = "Editor";
        bindings = {
          "ctrl-b" = "editor::ToggleGitBlame";
        };
      }
      {
        context = "Terminal";
        bindings = {
          "cmd-t" = "workspace::NewTerminal";
        };
      }
    ];
  };
}
