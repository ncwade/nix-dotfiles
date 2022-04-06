{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports = [
    ./common.nix
    (import "${home-manager}/nixos")
  ];

  home-manager.users.ncwade = { ... }: {
    imports = [ 
      ./cli.nix
      ./gui.nix
    ];
  };
}

