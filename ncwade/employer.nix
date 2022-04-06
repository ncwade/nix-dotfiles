{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports = [
    ../services/yubikey.nix
    (import "${home-manager}/nixos")
  ];

  home-manager.users.ncwade = {
    home.sessionVariables = {
      CONFIGURE_OPTS="--with-openssl=$(nix eval --raw nixpkgs.openssl.dev.outPath)";
      CPPFLAGS="-I$(nix eval --raw nixpkgs.zlib.dev.outPath)/include -I$(nix eval --raw nixpkgs.libffi.dev.outPath)/include -I$(nix eval --raw nixpkgs.openssl.dev.outPath)/include -I$(nix eval --raw nixpkgs.readline.dev.outPath)/include -I$(nix eval --raw nixpkgs.ncurses.dev.outPath)/include -I$(nix eval --raw nixpkgs.expat.dev.outPath)/include -I$(nix eval --raw nixpkgs.sqlite.dev.outPath)/include -I$(nix eval --raw nixpkgs.bzip2.dev.outPath)/include";
      LDFLAGS="-L$(nix eval --raw nixpkgs.zlib.out)/lib -L$(nix eval --raw nixpkgs.libffi.out)/lib -L$(nix eval --raw nixpkgs.openssl.out)/lib -L$(nix eval --raw nixpkgs.readline.outPath)/lib -L$(nix eval --raw nixpkgs.ncurses.out)/lib -L$(nix eval --raw nixpkgs.expat.outPath)/lib -L$(nix eval --raw nixpkgs.sqlite.out)/lib -L$(nix eval --raw nixpkgs.bzip2.out)/lib";
    };
    programs.go.enable = true;
    home.packages = [
      pkgs.fd
      pkgs.python3
      pkgs.kubectl
      pkgs.poetry
      pkgs.python3Packages.pipx
      pkgs.gnumake
      pkgs.binutils
      pkgs.zlib.dev
      pkgs.libffi.dev
      pkgs.openssl.dev
      pkgs.readline.dev
      pkgs.ncurses.dev
      pkgs.expat.dev
      pkgs.sqlite.dev
      pkgs.bzip2.dev
      pkgs.xz
      pkgs.gcc
      pkgs.nodejs
      pkgs.docker-compose
      pkgs.libcap
      pkgs.pre-commit
      pkgs.direnv
      pkgs.gh
      pkgs.pyright
    ];
  };
}

