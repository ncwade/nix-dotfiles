{ config, lib, ... }:

{
  programs.rex = {
    enable = true;
    config = ./rex/init.lua;
    # Keep SSH under its existing ownership rather than enabling HM's SSH module.
    sshGuard = false;
  };

  # The macOS app runs the server; services.rex remains disabled.
  xdg.configFile."rex/catppuccin-mocha.conf".source = ./ghostty-theme.conf;

  # Preserve the existing PATH entry, now using the official package's CLI.
  home.file.".local/bin/rex".source = "${config.programs.rex.package}/bin/rex";
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  # Rex maintains its Codex skill and session-context hook using the installed CLI.
  home.activation.installRexCodexSkills = lib.mkIf config.programs.rex.enable (
    lib.hm.dag.entryAfter [ "installCodexSkills" ] ''
      $DRY_RUN_CMD ${config.programs.rex.package}/bin/rex skill setup --agent codex
    ''
  );
}
