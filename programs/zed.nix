{pkgs, ...}:
{
  xdg.configFile."zed/settings.json".source = ./zed-settings.json;
  xdg.configFile."zed/keymap.json".source = ./zed-keymap.json;
}
