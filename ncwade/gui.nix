{ config, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    # TODO: This is broken for ungoogled chromium.
    # extensions = [
    #   { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
    #   { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1password
    #   { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # privacy badger
    # ];
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./config/kitty;
  };

  xdg.configFile."direnv/direnvrc".source = ./config/direnvrc;

  home.packages = [
    pkgs.barrier
    pkgs.kitty
  ];
}

