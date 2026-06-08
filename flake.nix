{
  description = "macOS provisioning with nix-darwin, Home Manager, and Homebrew Bundle";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      user = "andreausuelli";
      system = "aarch64-darwin";

      profiles = {
        home = {
          darwinModule = ./modules/darwin/home.nix;
          homeModule = ./modules/home/home.nix;
        };
        work = {
          darwinModule = ./modules/darwin/work.nix;
          homeModule = ./modules/home/work.nix;
        };
      };

      mkDarwin =
        role:
        let
          profile = profiles.${role};
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs role user;
          };
          modules = [
            ./modules/darwin/common.nix
            profile.darwinModule
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs role user;
              };
              home-manager.users.${user} = {
                imports = [
                  ./modules/home/common.nix
                  profile.homeModule
                ];
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        home = mkDarwin "home";
        work = mkDarwin "work";
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
