{ config, pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./config/kitty;
  };

  programs.firefox = {
    enable = true;
  };

  xdg.configFile."direnv/direnvrc".source = ./config/direnvrc;

  home.packages = [
    pkgs.barrier
    pkgs.kitty
  ];
}

