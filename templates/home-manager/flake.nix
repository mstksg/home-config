{
  description = "Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-config.url = "github:mstksg/home-config";
  };

  outputs = { nixpkgs, home-manager, home-config, ... }:
    let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      config = {
        # user = "";
        # email = "";
      };
    in
    {
      homeConfigurations.${config.user} =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            { inherit config; }
            home-config.nixosModules.base
            home-config.nixosModules.editing
            ./home.nix
          ];

        };
    };
}

