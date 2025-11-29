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
    ];
    userSettings = {
      theme = {
        mode = "system";
        dark = "Catppuccin Mocha";
        light = "One Light";
      };
      agent = {
        play_sound_when_agent_done = true;
        model_parameters = [ ];
      };
      edit_predictions = {
        mode = "eager";
      };
      icon_theme = "Catppuccin Mocha";
      ui_font_size = 14;
      buffer_font_family = "JetBrainsMono Nerd Font Mono";
      terminal = {
        line_height = "standard";
      };
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
