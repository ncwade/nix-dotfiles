{ ... }:
{
  programs.zed-editor = {
    enable = true;
    # Use the Homebrew-installed app on macOS and keep Home Manager for config only.
    package = null;
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
      # Sign in through Zed's AI settings with the ChatGPT account that owns
      # the subscription. Zed stores the resulting credentials in the system
      # keychain, rather than in this declarative settings file.
      disable_ai = false;
      colorize_brackets = true;
      theme = {
        mode = "system";
        dark = "Catppuccin Mocha";
        light = "One Light";
      };
      agent = {
        default_model = {
          provider = "openai-subscribed";
          model = "gpt-5.6-sol";
        };
        model_parameters = [ ];
        play_sound_when_agent_done = true;
      };
      agent_servers = {
        # The ACP Registry supplies and keeps this adapter current.
        codex-acp = {
          type = "registry";
        };
      };
      edit_predictions = {
        # ChatGPT subscriptions provide Zed Agent models, not edit predictions.
        provider = "none";
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
