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

  # Server-specific packages
  home.packages = with pkgs; [
    # Media management
    jellyfin-ffmpeg
    
    # Monitoring
    btop
    iotop
    
    # Network tools
    nmap
    iftop
  ];

  # Server-specific shell aliases
  programs.zsh.shellAliases = {
    nixos-rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#media";
    nixos-update = "cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake .#media";
    
    # Service management shortcuts
    jf-status = "systemctl status jellyfin";
    sonarr-status = "systemctl status sonarr";
    radarr-status = "systemctl status radarr";
    prowlarr-status = "systemctl status prowlarr";
    transmission-status = "systemctl status transmission";
    
    # Log viewing shortcuts
    jf-logs = "journalctl -u jellyfin -f";
    sonarr-logs = "journalctl -u sonarr -f";
    radarr-logs = "journalctl -u radarr -f";
  };

  # Server-specific update function
  programs.zsh.initContent = lib.mkOrder 600 ''
    update-all() {
        echo "Updating Nix flake..."
        cd /etc/nixos
        sudo nix flake update

        echo "Rebuilding NixOS system..."
        sudo nixos-rebuild switch --flake /etc/nixos#media
    }
    
    # Function to check all media services
    check-services() {
        echo "=== Media Services Status ==="
        for service in jellyfin sonarr radarr prowlarr transmission; do
            echo ""
            systemctl status $service --no-pager | head -n 3
        done
    }
  '';
}
