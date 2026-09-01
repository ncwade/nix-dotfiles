{ pkgs, ... }:
let
  starshipConfig = builtins.fromTOML (builtins.readFile ./starship.toml);
  starshipTmuxConfig = starshipConfig // {
    add_newline = true;
    format = "$directory$git_branch$git_status$kubernetes$cmd_duration$line_break$character";

    directory = {
      format = "[$path]($style)[$read_only]($read_only_style) ";
      truncation_length = 2;
      truncate_to_repo = true;
    };

    git_branch = (starshipConfig.git_branch or { }) // {
      format = "[$branch]($style) ";
      symbol = "";
      truncation_length = 24;
    };

    git_status = (starshipConfig.git_status or { }) // {
      format = "([$all_status$ahead_behind]($style) )";
    };

    kubernetes = (starshipConfig.kubernetes or { }) // {
      format = "[$symbol$context]($style) ";
    };

    cmd_duration = (starshipConfig.cmd_duration or { }) // {
      format = "[󰔛 $duration]($style) ";
    };
  };
in
{
  xdg.configFile."starship.toml".source = ./starship.toml;
  xdg.configFile."starship-tmux.toml".source =
    (pkgs.formats.toml { }).generate "starship-tmux.toml" starshipTmuxConfig;
}
