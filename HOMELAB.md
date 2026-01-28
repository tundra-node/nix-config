# 🏠 Homelab NixOS Configuration

NixOS configurations for homelab VMs running on Proxmox cluster (daedalus + helios).

## 🖥️ Virtual Machines

| VM | Hostname | IP | Purpose | Services |
|----|----------|----|---------| ---------|
| **101** | media-nixos | 10.0.0.101 | Media Server | Jellyfin, Sonarr, Radarr, Prowlarr, Transmission, Jellyseerr |
| **102** | immich-nixos | 10.0.0.102 | Photo Management | Immich |
| **103** | navidrome-nixos | 10.0.0.103 | Music Streaming | Navidrome |

## 📋 Prerequisites

- Proxmox cluster (daedalus at 10.0.0.75, helios at 10.0.0.76)
- NixOS 25.05 installed on each VM
- External 2TB HDD mounted on helios at `/mnt/ext-media`
- NFS server configured on helios
- SSH access from your workstation

## 🚀 Quick Start

### 1. Clone Configuration to Each VM

On each VM after NixOS installation:

```bash
# Clone the config
git clone https://github.com/tundra-node/nix-config ~/.config/nix-config
cd ~/.config/nix-config

# Copy hardware configuration
sudo cp /etc/nixos/hardware-configuration.nix ./hosts/homelab/[media|photos|music]/
```

### 2. Add Your SSH Key

Edit the configuration files and add your SSH public key:

```nix
users.users.homelab = {
  # ...
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3... your-actual-key-here"
  ];
};
```

### 3. Create Symlink and Build

```bash
# Remove default config
sudo rm -rf /etc/nixos

# Create symlink
sudo ln -s ~/.config/nix-config /etc/nixos

# Update flake
cd /etc/nixos
sudo nix flake update

# Build (use appropriate hostname: media, photos, or music)
sudo nixos-rebuild switch --flake .#media
```

## 🎬 VM 101: Media Server Setup

### Storage Configuration

The media server mounts the 2TB external drive via NFS from helios:

```
/mnt/storage → 10.0.0.76:/mnt/ext-media (NFS)
```

### First-Time Setup

1. **Apply configuration:**
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#media
   ```

2. **Configure Mullvad VPN:**
   - Get WireGuard config from https://mullvad.net/en/account/#/wireguard-config/
   - Create `/root/mullvad.conf` with your configuration
   - Restart services

3. **Configure services:**
   - Jellyfin: http://10.0.0.101:8096
   - Sonarr: http://10.0.0.101:8989
   - Radarr: http://10.0.0.101:7878
   - Prowlarr: http://10.0.0.101:9696
   - Transmission: http://10.0.0.101:9091
   - Jellyseerr: http://10.0.0.101:5055

### Configuration Order

1. **Prowlarr** → Add indexers
2. **Sonarr** → Connect Prowlarr, Transmission, set `/mnt/storage/media/tvshows`
3. **Radarr** → Connect Prowlarr, Transmission, set `/mnt/storage/media/movies`
4. **Jellyseerr** → Connect to Jellyfin, Sonarr, Radarr
5. **Jellyfin** → Add media libraries

## 📸 VM 102: Photos Server Setup

### Storage Configuration

Photos are stored on the VM's second disk:

```
/mnt/photos → /dev/disk/by-label/photos (local ext4)
```

### First-Time Setup

1. **Apply configuration:**
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#photos
   ```

2. **Set up Immich:**
   ```bash
   # Create immich directory
   mkdir -p ~/immich
   cd ~/immich
   
   # Copy docker-compose files from the config
   cp /etc/nixos/hosts/homelab/photos/docker-compose.yml .
   cp /etc/nixos/hosts/homelab/photos/env.example .env
   
   # Start Immich
   docker compose up -d
   ```

3. **Access Immich:**
   - Open http://10.0.0.102:2283
   - Create admin account
   - Start uploading photos!

### Immich Management

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Update images
docker compose pull
docker compose up -d

# Backup database
docker exec immich_postgres pg_dump -U postgres immich > backup.sql
```

## 🎵 VM 103: Music Server Setup

### Storage Configuration

Music is stored on the VM's second disk:

```
/mnt/music → /dev/disk/by-label/music (local ext4)
```

### First-Time Setup

1. **Apply configuration:**
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#music
   ```

2. **Add music files:**
   ```bash
   # Copy music to /mnt/music
   # Navidrome will automatically scan on startup
   ```

3. **Access Navidrome:**
   - Open http://10.0.0.103:4533
   - Create admin account
   - Start streaming!

### Navidrome Management

```bash
# Check status
systemctl status navidrome

# View logs
journalctl -u navidrome -f

# Trigger rescan
sudo systemctl restart navidrome
```

## 🔧 Common Tasks

### Update All Systems

On each VM:

```bash
update-all
```

Or manually:

```bash
cd /etc/nixos
sudo nix flake update
sudo nixos-rebuild switch --flake .#[media|photos|music]
```

### Check Service Status

**Media server:**
```bash
check-services
```

**Photos server:**
```bash
dps  # Docker ps
dcl  # Docker compose logs
```

**Music server:**
```bash
nd-status
music-stats
```

### Backup Configurations

```bash
# The NixOS configs are in git - just push!
cd /etc/nixos
git add .
git commit -m "Update homelab config"
git push

# Backup Immich database
cd ~/immich
docker exec immich_postgres pg_dump -U postgres immich > immich-backup-$(date +%Y%m%d).sql

# Backup is automatic for media server (configured in NixOS)
```

## 🌐 Network Access

### Local Access

Direct access via IPs:
- Media: 10.0.0.101
- Photos: 10.0.0.102
- Music: 10.0.0.103

### Remote Access

Connect via WireGuard VPN through daedalus (10.0.0.75), then access all services.

## 🔐 Security

- SSH key authentication only (no passwords)
- Firewall enabled on all VMs
- Mullvad VPN for torrent traffic
- Regular security updates enabled

## 📊 Monitoring

Each VM includes:
- `htop` - Process monitoring
- `btop` - Modern resource monitor
- `iotop` - I/O monitoring
- System logs via `journalctl`

## 🆘 Troubleshooting

### Services Won't Start

```bash
# Check service status
systemctl status [service-name]

# View full logs
journalctl -u [service-name] -n 100

# Restart service
sudo systemctl restart [service-name]
```

### NFS Mount Issues (Media Server)

```bash
# Check NFS mount
df -h | grep storage

# Remount
sudo umount /mnt/storage
sudo mount -a

# Check NFS server (on helios)
showmount -e 10.0.0.76
```

### Docker Issues (Photos Server)

```bash
# Check Docker daemon
systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Clean up
docker system prune -a
```

## 📝 Notes

- All configurations are declarative - changes require rebuild
- Hardware configurations are system-specific (not in git)
- User is `homelab` on all VMs
- Default timezone is America/New_York (change in configuration.nix)

## 🤝 Contributing

This is a personal homelab setup, but feel free to fork and adapt for your own use!

---

**Quick Reference:**
- Media: `sudo nixos-rebuild switch --flake /etc/nixos#media`
- Photos: `sudo nixos-rebuild switch --flake /etc/nixos#photos`
- Music: `sudo nixos-rebuild switch --flake /etc/nixos#music`
