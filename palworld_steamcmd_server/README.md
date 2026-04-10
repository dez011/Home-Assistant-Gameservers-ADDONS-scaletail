<p align="center">
  <img src="https://raw.githubusercontent.com/dez011/Home-Assistant-Gameservers-ADDONS-scaletail/main/palworld_steamcmd_server/banner.jpg" alt="Home Assistant Game Servers Add-ons" width="50%">
</p>

<h1 align="center">
   🦖 Palworld Dedicated Server (SteamCMD + Tailscale)
</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Home%20Assistant-OS-blue" alt="Home Assistant OS">
  <img src="https://img.shields.io/badge/Architecture-amd64-blue" alt="Architecture">
  <img src="https://img.shields.io/badge/SteamCMD-Enabled-orange" alt="SteamCMD">
  <img src="https://img.shields.io/badge/Tailscale-Supported-blue" alt="Tailscale">
  <img src="https://img.shields.io/badge/Status-Beta-orange" alt="Status">
</p>

A Home Assistant OS add-on to run a fully host-based **Palworld Dedicated Server**
using **SteamCMD** with optional **Tailscale** networking for secure remote access.

---

## 🚀 Overview

This add-on runs a **Palworld Dedicated Server** directly on **Home Assistant OS**.

All data is stored entirely on the host under `/share`, including:

- SteamCMD
- Palworld server files
- Configuration
- Savegames
- Tailscale state (persistent across restarts)

No additional server, virtual machine, or external host is required.

---

## ✨ Features

- Official Palworld Dedicated Server (Steam App ID `2394010`)
- Automatic updates via SteamCMD
- Persistent data storage under `/share`
- Runs directly on Home Assistant OS
- Easy installation via the Home Assistant Add-on Store
- **Optional Tailscale integration** — access your server securely from anywhere without port forwarding

---

## 📦 Installation

1. Open **Home Assistant**
2. Go to **Settings → Add-ons → Add-on Store**
3. Add the following repository:
   ```
   https://github.com/dez011/Home-Assistant-Gameservers-ADDONS-scaletail
   ```
4. Install **Palworld Dedicated Server**
5. Start the add-on

---

## 📁 Data Location

All server data is stored persistently under:

```text
/share/palworld/
├── server/      ← Palworld server files
├── config/      ← Configuration files
├── savegames/   ← World save data
├── steam_home/  ← SteamCMD home
└── tailscale/   ← Tailscale persistent state
```

You can access this directory from Windows via:

```
\\<HOME_ASSISTANT_IP>\share\palworld\
```

---

## 🎮 Server Configuration

Server configuration is done via configuration files.

Main configuration file:

```
/share/palworld/config/PalWorldSettings.ini
```

After editing the configuration file, restart the add-on for changes to take effect.

---

## 🌐 Network Ports

| Port  | Protocol | Description  |
|-------|----------|--------------|
| 8211  | UDP      | Game server  |
| 27015 | UDP      | Query port   |

Make sure these ports are forwarded on your router if you want external players to join **without** Tailscale.

> 💡 **With Tailscale enabled**, players on your Tailnet can connect directly using the Tailscale IP — **no port forwarding required!**

---

## ⚙️ Add-on Options

### General Options

| Option           | Type   | Default     | Description                                    |
|------------------|--------|-------------|------------------------------------------------|
| `app_id`         | int    | `2394010`   | Steam App ID for Palworld Dedicated Server     |
| `steam_user`     | string | `anonymous` | Steam username for SteamCMD login              |
| `steam_pass`     | string | *(empty)*   | Steam password (optional, for non-anonymous)   |
| `update_on_boot` | bool   | `true`      | Automatically update the server on start       |

### 🔗 Tailscale Options

| Option                          | Type   | Default     | Description                                                                 |
|---------------------------------|--------|-------------|-----------------------------------------------------------------------------|
| `tailscale_enabled`             | bool   | `false`     | Enable Tailscale networking                                                 |
| `tailscale_authkey`             | string | *(empty)*   | Tailscale auth key ([generate one here](https://login.tailscale.com/admin/settings/keys)) |
| `tailscale_hostname`            | string | `palworld`  | Hostname for this device on your Tailnet                                    |
| `tailscale_accept_dns`          | bool   | `false`     | Accept DNS settings from Tailscale (MagicDNS)                               |
| `tailscale_advertise_exit_node` | bool   | `false`     | Advertise this node as an exit node                                         |
| `tailscale_serve_enabled`       | bool   | `false`     | Enable Tailscale Serve to proxy a local TCP port via HTTPS                  |
| `tailscale_serve_port`          | int    | `8212`      | Local TCP port to proxy through Tailscale Serve (e.g. RCON web panel)       |
| `tailscale_funnel`              | bool   | `false`     | Expose the served port to the public internet via Tailscale Funnel          |

---

## 🔗 Tailscale Setup Guide

[Tailscale](https://tailscale.com) creates a secure mesh VPN (Tailnet) between your devices. With Tailscale enabled, your Palworld server gets its own Tailscale IP and players on your Tailnet can connect directly — **no port forwarding or firewall changes needed**.

### Step 1: Get a Tailscale Auth Key

1. Sign up / log in at [https://login.tailscale.com](https://login.tailscale.com)
2. Go to **Settings → Keys**
3. Generate a new **Auth Key** (reusable recommended)
4. Copy the key

### Step 2: Configure the Add-on

In the add-on configuration:

1. Set `tailscale_enabled` to **true**
2. Paste your auth key into `tailscale_authkey`
3. Optionally change `tailscale_hostname` (default: `palworld`)
4. Start the add-on

### Step 3: Connect

Once the add-on starts, the log will show the Tailscale IP:

```
✅ Tailscale: Connected! Tailscale IP: 100.x.x.x
   Players on your Tailnet can connect to: 100.x.x.x:8211
```

Players with Tailscale installed can connect to `100.x.x.x:8211` (or `palworld:8211` if using MagicDNS).

### Optional: Tailscale Serve / Funnel

If you're running an RCON web panel or any HTTP service alongside the game server:

- **Tailscale Serve** proxies a local HTTP port via HTTPS on your Tailnet
- **Tailscale Funnel** exposes it to the public internet

Set `tailscale_serve_enabled` to `true` and configure `tailscale_serve_port` to the local port of your web service.

---

## ❤️ Support & Donations

This project is developed and maintained in my free time.

If you enjoy this add-on and find it useful,
I would really appreciate a small donation to support my work and ongoing development.

👉 **Donate via PayPal:** [paypal.me/cyclemat](http://paypal.me/cyclemat)

Donations are completely optional – thank you very much!

🧑‍💻 Maintainer
Author: CyCleMat

GitHub: https://github.com/dez011

📜 Disclaimer
This add-on is not affiliated with or endorsed by Pocketpair or Palworld developers.
All trademarks and game content belong to their respective owners.

<p align="center">
  <img src="https://raw.githubusercontent.com/dez011/Home-Assistant-Gameservers-ADDONS-scaletail/main/assets/logo.png" width="200">
</p>

<p align="center">
  <strong>Have fun surviving, collecting Pals and automating your Palworld! 🐾⚙️</strong>
</p>
