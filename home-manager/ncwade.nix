{ config, pkgs, ... }:

{
  imports = [
    ../programs/ghostty.nix
    ../programs/zed.nix
    ../programs/starship.nix
    ../programs/fish.nix
    ../programs/nu.nix
  ];
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;
  programs.nushell.enable = true;
  home.packages = with pkgs; [
    pkgs.direnv
    pkgs.ripgrep
    pkgs.bat
    pkgs.fzf
    pkgs.fd
    pkgs.television
    pkgs.mise
    pkgs.gh
    pkgs.codex
    pkgs.grype
    pkgs.coreutils
    pkgs.grype
    pkgs.jj
    pkgs.jq
    pkgs.k9s
    pkgs.pipx
    pkgs.kubectl
    pkgs.kubectl-cnpg
    pkgs.opentofu
    pkgs.prettier
    pkgs.skopeo
    pkgs.sshpass
    pkgs.syft
    pkgs.terragrunt
    pkgs.tmux
    pkgs.watch
    pkgs.wget
    pkgs.yamlfmt
    pkgs.yarn
    pkgs.yq
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  xdg.enable = true;
  xdg.configHome = "/Users/ncwade/.config";
}
