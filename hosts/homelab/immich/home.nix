{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../modules/shared/programs.nix
    ../../../modules/shared/shell.nix
    ../../../modules/shared/git.nix
    ../../../modules/shared/multiplexer.nix
    ../../../modules/shared/fastfetch.nix
  ];

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # Photos server-specific packages
  home.packages = with pkgs; [
    # Image processing tools
    imagemagick
    exiftool
    
    # Monitoring
    btop
    iotop
    
    # Docker management
    dive  # Docker image explorer
    ctop  # Container metrics
  ];

  # Server-specific shell aliases
  programs.zsh.shellAliases = {
    nixos-rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#photos";
    nixos-update = "cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake .#photos";
    
    # Docker shortcuts
    dps = "docker ps";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
    dcl = "docker compose logs -f";
    
    # Immich shortcuts
    immich-up = "cd ~/immich && docker compose up -d";
    immich-down = "cd ~/immich && docker compose down";
    immich-logs = "cd ~/immich && docker compose logs -f";
    immich-restart = "cd ~/immich && docker compose restart";
  };

  # Server-specific update function
  programs.zsh.initContent = lib.mkOrder 600 ''
    update-all() {
        echo "Updating Nix flake..."
        cd /etc/nixos
        sudo nix flake update

        echo "Rebuilding NixOS system..."
        sudo nixos-rebuild switch --flake /etc/nixos#photos
        
        echo "Updating Docker images..."
        cd ~/immich
        docker compose pull
        docker compose up -d
    }
  '';
}
