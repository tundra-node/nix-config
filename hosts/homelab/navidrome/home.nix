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

  # Music server-specific packages
  home.packages = with pkgs; [
    # Audio tools
    ffmpeg-full
    flac
    lame
    sox
    
    # Music file management
    beets
    picard  # MusicBrainz Picard
    
    # Monitoring
    btop
    iotop
  ];

  # Server-specific shell aliases
  programs.zsh.shellAliases = {
    nixos-rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#music";
    nixos-update = "cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake .#music";
    
    # Navidrome shortcuts
    nd-status = "systemctl status navidrome";
    nd-restart = "sudo systemctl restart navidrome";
    nd-logs = "journalctl -u navidrome -f";
    nd-scan = "sudo systemctl restart navidrome";  # Triggers a scan
    
    # Music directory shortcuts
    music = "cd /mnt/music";
  };

  # Server-specific update function
  programs.zsh.initContent = lib.mkOrder 600 ''
    update-all() {
        echo "Updating Nix flake..."
        cd /etc/nixos
        sudo nix flake update

        echo "Rebuilding NixOS system..."
        sudo nixos-rebuild switch --flake /etc/nixos#music
        
        echo "Restarting Navidrome to trigger rescan..."
        sudo systemctl restart navidrome
    }
    
    # Function to check music collection stats
    music-stats() {
        echo "=== Music Collection Statistics ==="
        echo "Total files: $(find /mnt/music -type f | wc -l)"
        echo "Total size: $(du -sh /mnt/music | cut -f1)"
        echo ""
        echo "File types:"
        find /mnt/music -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn
    }
  '';
}
