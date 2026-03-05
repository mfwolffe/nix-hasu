{
  description = "hasu NixOS configuration with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mfwolffe-pkgs = {
      url = "path:/home/mfwolffe/GithubOrgs/mfwolffe/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, mfwolffe-pkgs, ... }: {
    nixosConfigurations.hasu = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit mfwolffe-pkgs; };
      modules = [
        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.mfwolffe = import ./home.nix;
        }
      ];
    };
  };
}
