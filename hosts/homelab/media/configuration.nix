{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "media-nixos";

  networking = {
    interfaces.ens18 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "10.0.0.101";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.0.1";
    nameservers = [ "10.0.0.75" ];
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8096 8989 7878 9696 9091 5055 ];
      allowedUDPPorts = [ 51820 ];
    };
  };

  services.qemuGuestAgent.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.homelab = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3... your-key-here"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Mount NFS share from helios
  fileSystems."/mnt/storage" = {
    device = "10.0.0.76:/mnt/ext-media";
    fsType = "nfs";
    options = [ "nfsvers=4.2" "rw" "noatime" ];
  };

  services.rpcbind.enable = true;

  # Nixflix configuration
  services.nixflix = {
    enable = true;
    
    # Paths on external drive
    mediaDir = "/mnt/storage/media";
    downloadDir = "/mnt/storage/downloads";
    
    # Service configs
    jellyfin = {
      enable = true;
      openFirewall = true;
      # Jellyfin will find movies, TV, music, photos here
      mediaLocations = {
        movies = "/mnt/storage/media/movies";
        tv = "/mnt/storage/media/tvshows";
        music = "/mnt/storage/media/music";
        photos = "/mnt/storage/photos";
      };
    };
    
    sonarr = {
      enable = true;
      openFirewall = true;
    };
    
    radarr = {
      enable = true;
      openFirewall = true;
    };
    
    prowlarr = {
      enable = true;
      openFirewall = true;
    };
    
    transmission = {
      enable = true;
      openFirewall = true;
      settings = {
        download-dir = "/mnt/storage/downloads";
        incomplete-dir = "/mnt/storage/downloads/.incomplete";
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist = "10.0.0.*,127.0.0.1";
      };
    };
    
    jellyseerr = {
      enable = true;
      openFirewall = true;
    };

    # VPN - using secrets outside git
    vpn = {
      enable = true;
      provider = "mullvad";
      configFile = "/root/secrets/mullvad.conf";  # NOT in git!
    };
  };

  environment.systemPackages = with pkgs; [
    nano wget curl git htop tmux unzip nfs-utils wireguard-tools
  ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "24.05";
}