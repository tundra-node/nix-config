{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = "immich-nixos";
    interfaces.ens18 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "10.0.0.102";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.0.1";
    nameservers = [ "10.0.0.75" ];
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        22     # SSH
        2283   # Immich
      ];
    };
  };

  # Time zone and locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Proxmox guest agent
  services.qemuGuestAgent.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # User
  users.users.homelab = {
    isNormalUser = true;
    description = "Homelab User";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-key-here"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Mount storage disk for photos
  fileSystems."/mnt/photos" = {
    device = "/dev/disk/by-label/photos";
    fsType = "ext4";
  };

  # Enable Docker for Immich
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Create directory structure
  systemd.tmpfiles.rules = [
    "d /mnt/photos/library 0755 homelab users"
    "d /mnt/photos/upload 0755 homelab users"
    "d /mnt/photos/backups 0755 homelab users"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tmux
    docker-compose
  ];

  # Enable zsh
  programs.zsh.enable = true;

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "25.05";
}
