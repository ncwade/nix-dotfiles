{ pkgs, lib, ... }:

let
  darwinCliPackageNames = import ./darwin-cli-packages.nix;
  guiApps = import ./gui-apps.nix;
  guiPackageNames = guiApps.common ++ guiApps.darwin;
  packageFor = name:
    lib.attrByPath (lib.splitString "." name)
      (throw "missing nixpkgs package: ${name}")
      pkgs;
  darwinCliPackages = builtins.map packageFor darwinCliPackageNames;
  guiPackages = builtins.map packageFor guiPackageNames;
  kubectlKrew = pkgs.symlinkJoin {
    name = "kubectl-krew-${pkgs.krew.version}";
    paths = [ pkgs.krew ];
    postBuild = ''
      ln -s "$out/bin/krew" "$out/bin/kubectl-krew"
    '';
  };
  pipx = pkgs.pipx.overrideAttrs (oldAttrs: {
    disabledTestPaths = (oldAttrs.disabledTestPaths or []) ++ [
      "tests/test_inject.py"
    ];
    disabledTests = (oldAttrs.disabledTests or []) ++ [
      "test_fix_package_name"
      "test_parse_specifier_for_metadata"
    ];
  });
in

{
  imports = [
    ../programs/amp.nix
    ../programs/codex.nix
    ../programs/ghostty.nix
    ../programs/opencode.nix
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
    kubectlKrew
    pipx
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
    pkgs.yq-go
    pkgs.nil
    pkgs.nixd
    pkgs.opencode
    pkgs.librsvg
  ] ++ darwinCliPackages ++ guiPackages;

  xdg.enable = true;
  xdg.configHome = "/Users/ncwade/.config";

  programs.git = {
    enable = true;
    settings = {
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICy5wxb5jwVx1YDgXpGBVIF50w/i6R+RjuPfi2/btBLW SSH Key";
      commit.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      core.sshCommand = "ssh -o PubkeyAcceptedAlgorithms=+ssh-ed25519 -o 'IdentityAgent=\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"'";
      user.name = "Nick Wade";
      user.email = "me@ncwade.com";
      init.defaultBranch = "main";
    };
    includes = [
      {
        condition = "gitdir/i:~/src/github.com/ncwade/";
        contents.user.email = "me@ncwade.com";
      }
    ];
  };
}
