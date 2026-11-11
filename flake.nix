{
  description = "Personal Home Manager profiles and user programs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rex.url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
    rex.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { rex, ... }: {
    homeManagerModules = {
      desktop = import ./home-manager/ncwade.nix;
      cli = import ./home-manager/ncwade-cli.nix;
      mvm = import ./home-manager/mvm.nix;
      rex = {
        imports = [
          rex.homeManagerModules.default
          ./programs/rex.nix
        ];
      };
    };
  };
}
