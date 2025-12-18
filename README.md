# Pterodactyl Wings for DomCloud

Complete Pterodactyl Wings installation package for DomCloud with Rootless Docker support.

## Features
- ✅ **Rootless Docker** - No sudo/root required
- ✅ **Auto-configuration** - Minimal setup needed
- ✅ **Health Monitoring** - Automatic health checks
- ✅ **Auto-Update** - Watchtower integration
- ✅ **Secure** - Limited capabilities, no privileges

## Quick Installation
1. Add this repository to your DomCloud account
2. Click "Install" on Pterodactyl Wings
3. Configure:
   - **Panel URL**: Your Pterodactyl panel address
   - **Node Token**: From Panel → Nodes → Configuration
   - **Node ID**: From your panel (default: 1)
4. Click "Deploy" and wait for installation

## Manual Installation
```bash
git clone https://github.com/anas-scripts/pterodactyl-wings-domcloud.git
cd pterodactyl-wings-domcloud
./install.sh
