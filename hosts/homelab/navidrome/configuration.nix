{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = "navidrome-nixos";
    interfaces.ens18 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "10.0.0.103";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.0.1";
    nameservers = [ "10.0.0.75" ];
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        22     # SSH
        4533   # Navidrome
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
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-key-here"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Mount storage disk for music
  fileSystems."/mnt/music" = {
    device = "10.0.0.76:/mnt/ext-media";
    fsType = "nfs";
    options = ["nfsvers=4.2" "rw" "noatime"];
  };

  # Navidrome service
  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/mnt/music";
      DataFolder = "/var/lib/navidrome";
      CacheFolder = "/var/cache/navidrome";
      LogLevel = "info";
      ScanSchedule = "@every 1h";
      SessionTimeout = "24h";
      EnableTranscodingConfig = true;
      # Additional settings
      UIWelcomeMessage = "Welcome to Navidrome";
    };
  };

  # Create directory structure
  systemd.tmpfiles.rules = [
    "d /mnt/music 0755 navidrome navidrome"
    "d /var/cache/navidrome 0755 navidrome navidrome"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    nano
    wget
    curl
    git
    htop
    tmux
    # Audio tools
    ffmpeg
    flac
    lame
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
