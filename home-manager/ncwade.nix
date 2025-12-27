{ pkgs, ... }:

{
  imports = [
    ../programs/ghostty.nix
    ../programs/zed.nix
    ../programs/starship.nix
    ../programs/fish.nix
    ../programs/tmux.nix
  ];
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;
  programs.nushell.enable = true;
  home.packages = [
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
    pkgs.jj
    pkgs.jq
    pkgs.k9s
    pkgs.pipx
    pkgs.kubectl
    pkgs.kubectl-cnpg
    pkgs.prettier
    pkgs.skopeo
    pkgs.sshpass
    pkgs.syft
    pkgs.watch
    pkgs.wget
    pkgs.yamlfmt
    pkgs.yarn
    pkgs.yq
    pkgs.nil
    pkgs.nixd
    pkgs.opencode
  ];

  xdg.enable = true;
  xdg.configHome = "/Users/ncwade/.config";

  programs.git = {
    enable = true;
    settings = {
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICy5wxb5jwVx1YDgXpGBVIF50w/i6R+RjuPfi2/btBLW SSH Key";
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.name = "Nick Wade";
      user.email = "me@ncwade.com";
      init.defaultBranch = "main";
    };
  };
}
