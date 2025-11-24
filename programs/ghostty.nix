{pkgs, ...}: let
  ghosttySettings = {
    "font-size" = 14;
    "theme" = "theme.conf";
    "title" = "";
    "mouse-hide-while-typing" = true;
    "command" = "/run/current-system/sw/bin/fish --login --interactive";
  };

  ghosttyToml = (pkgs.formats.toml {}).generate "ghostty-config" ghosttySettings;
in {
  xdg.configFile."ghostty/themes/theme.conf".source = ./ghostty-theme.conf;
  xdg.configFile."ghostty/config".source = ghosttyToml;
}
