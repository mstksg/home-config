{
  description = "Home config manager";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.follows = "home-manager/nixpkgs";
  };

  outputs = { nixpkgs, home-manager, self, ... }: {
    nixosModules = {
      base = import ./modules/base.nix;
      editing = import ./modules/editing.nix;
    };
    templates = {
      basic = {
        path = ./templates/home-manager;
        description = "Set up home config";
      };
      default = self.templates.basic;
    };

  };
}
