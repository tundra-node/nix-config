{
  description = "Multi-system nix configuration with Everforest theme + Homelab";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixflix.url = "github:kiriwalawren/nixflix";
  };
  
  outputs = { self, nixpkgs, darwin, home-manager, nixflix, ... }:
  let
    # macOS M2
    darwinSystem = "aarch64-darwin";
    darwinPkgs = import nixpkgs { 
      system = darwinSystem;
      config.allowUnfree = true;
    };
    
    # NixOS Intel
    linuxSystem = "x86_64-linux";
    linuxPkgs = import nixpkgs { 
      system = linuxSystem;
      config.allowUnfree = true;
    };
  in {
    # macOS configuration
    darwinConfigurations.macbook = darwin.lib.darwinSystem {
      system = darwinSystem;
      pkgs = darwinPkgs;
      modules = [
        ./hosts/darwin/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.elias = import ./hosts/darwin/home.nix;
        }
      ];
    };
    
    # NixOS laptop configuration
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      pkgs = linuxPkgs;
      modules = [
        ./hosts/nixos/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.tundra = import ./hosts/nixos/home.nix;
        }
      ];
    };
    
    # Homelab: Media Server (VM 101)
    nixosConfigurations.media = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      pkgs = linuxPkgs;
      modules = [
        ./hosts/homelab/media/configuration.nix
        home-manager.nixosModules.home-manager
        nixflix.nixosModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.homelab = import ./hosts/homelab/media/home.nix;
        }
      ];
    };
    
    # Homelab: Photos Server (VM 102)
    nixosConfigurations.photos = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      pkgs = linuxPkgs;
      modules = [
        ./hosts/homelab/photos/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.homelab = import ./hosts/homelab/photos/home.nix;
        }
      ];
    };
    
    # Homelab: Music Server (VM 103)
    nixosConfigurations.music = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      pkgs = linuxPkgs;
      modules = [
        ./hosts/homelab/music/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.homelab = import ./hosts/homelab/music/home.nix;
        }
      ];
    };
  };
}
