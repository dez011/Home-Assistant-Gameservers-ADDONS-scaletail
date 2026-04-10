<p align="center">
  <img src="https://raw.githubusercontent.com/dez011/Home-Assistant-Gameservers-ADDONS-scaletail/main/palworld_steamcmd_server/banner.jpg" alt="Home Assistant Game Servers Add-ons" width="50%">
</p>

<h1 align="center">
   🦖 Palworld Dedicated Server (SteamCMD + Tailscale + Discord)
</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Home%20Assistant-OS-blue" alt="Home Assistant OS">
  <img src="https://img.shields.io/badge/Architecture-amd64-blue" alt="Architecture">
  <img src="https://img.shields.io/badge/SteamCMD-Enabled-orange" alt="SteamCMD">
  <img src="https://img.shields.io/badge/Tailscale-Supported-blue" alt="Tailscale">
  <img src="https://img.shields.io/badge/Discord-Webhooks-5865F2" alt="Discord">
  <img src="https://img.shields.io/badge/RCON-Enabled-green" alt="RCON">
  <img src="https://img.shields.io/badge/Status-Beta-orange" alt="Status">
</p>

A Home Assistant OS add-on to run a fully host-based **Palworld Dedicated Server**
using **SteamCMD** with optional **Tailscale** networking and **Discord webhook** notifications.

> **Drop-in replacement for [`thijsvanloef/palworld-server-docker`](https://github.com/thijsvanloef/palworld-server-docker)** — all the same settings, now configurable directly from the Home Assistant UI.

---

## 🚀 Overview

This add-on runs a **Palworld Dedicated Server** directly on **Home Assistant OS**.

All data is stored entirely on the host under `/share`, including:

- SteamCMD
- Palworld server files
- Configuration (auto-generated from UI settings)
- Savegames
- Tailscale state (persistent across restarts)

No additional server, virtual machine, or external host is required.

---

## ✨ Features

- Official Palworld Dedicated Server (Steam App ID `2394010`)
- Automatic updates via SteamCMD
- Persistent data storage under `/share`
- **All game settings configurable from the HA UI** — no manual INI editing
- **Discord webhook notifications** — server update, online, shutdown, player join/leave
- **RCON support** with graceful save & shutdown
- **Player join/leave monitoring** via RCON (powers Discord notifications)
- **Optional Tailscale integration** — access your server securely from anywhere without port forwarding
- Tailscale Serve & Funnel support

---

## 📦 Installation

1. Open **Home Assistant**
2. Go to **Settings → Add-ons → Add-on Store**
3. Add the following repository:
   ```
   https://github.com/dez011/Home-Assistant-Gameservers-ADDONS-scaletail
   ```
4. Install **Palworld Dedicated Server**
5. Configure your settings in the **Configuration** tab
6. Start the add-on

---

## 📁 Data Location

All server data is stored persistently under:

```text
/share/palworld/
├── server/      ← Palworld server files
├── config/      ← PalWorldSettings.ini (auto-generated from UI)
├── steam_home/  ← SteamCMD home
└── tailscale/   ← Tailscale persistent state
```

You can access this directory from Windows via:

```
\\<HOME_ASSISTANT_IP>\share\palworld\
```

---

## ⚙️ Add-on Options

All settings below are configurable directly from the Home Assistant add-on **Configuration** tab.

### 🔧 SteamCMD

| Option           | Type   | Default     | Description                                    |
|------------------|--------|-------------|------------------------------------------------|
| `app_id`         | int    | `2394010`   | Steam App ID for Palworld Dedicated Server     |
| `steam_user`     | string | `anonymous` | Steam username for SteamCMD login              |
| `steam_pass`     | string | *(empty)*   | Steam password (optional, for non-anonymous)   |
| `update_on_boot` | bool   | `true`      | Automatically update the server on start       |

### 🖥️ Server Settings

| Option                  | Type   | Default                                    | Description                                   |
|-------------------------|--------|--------------------------------------------|-----------------------------------------------|
| `server_name`           | string | `pal-world-server-docker by Thijs van Loef`| Server name shown in server browser           |
| `server_description`    | string | `palworld-server-docker by Thijs van Loef` | Server description                            |
| `server_password`       | string | *(empty)*                                  | Password to join the server                   |
| `admin_password`        | string | `admin`                                    | Admin/RCON password                           |
| `server_player_max_num` | int    | `16`                                       | Maximum number of players                     |
| `port`                  | int    | `8211`                                     | Game port (UDP)                               |
| `query_port`            | int    | `27015`                                    | Query port (UDP)                              |
| `multithreading`        | bool   | `true`                                     | Enable multithreading                         |
| `community_server`      | bool   | `false`                                    | Show in community servers tab                 |
| `crossplay_platforms`   | string | `Steam,Xbox,PS5,Mac`                       | Allowed crossplay platforms                   |

### 🎮 RCON

| Option         | Type | Default | Description                              |
|----------------|------|---------|------------------------------------------|
| `rcon_enabled` | bool | `true`  | Enable RCON (needed for Discord join/leave + graceful shutdown) |
| `rcon_port`    | int  | `25575` | RCON port                                |

### ⚡ Gameplay Rates

| Option               | Type  | Default | Description              |
|----------------------|-------|---------|--------------------------|
| `daytime_speedrate`  | float | `0.9`   | Day time speed rate      |
| `nighttime_speedrate`| float | `1.25`  | Night time speed rate    |
| `exp_rate`           | float | `3.0`   | Experience rate          |
| `pal_capture_rate`   | float | `1.2`   | Pal capture rate         |
| `pal_spawn_num_rate` | float | `1.3`   | Pal spawn number rate    |
| `difficulty`         | string| `Hard`  | Difficulty (None/Normal/Hard) |

### 🧑 Player Settings

| Option                              | Type  | Default | Description                        |
|-------------------------------------|-------|---------|------------------------------------|
| `player_damage_rate_attack`         | float | `1.0`   | Player attack damage multiplier    |
| `player_damage_rate_defense`        | float | `0.8`   | Player defense damage multiplier   |
| `player_stomach_decrease_rate`      | float | `0.4`   | Player hunger decrease rate        |
| `player_stamina_decrease_rate`      | float | `0.4`   | Player stamina decrease rate       |
| `player_auto_hp_regen_rate`         | float | `1.0`   | Player HP regen rate               |
| `player_auto_hp_regen_rate_in_sleep`| float | `1.0`   | Player HP regen rate while sleeping|

### 🐾 Pal Settings

| Option                            | Type  | Default | Description                      |
|-----------------------------------|-------|---------|----------------------------------|
| `pal_damage_rate_attack`          | float | `1.0`   | Pal attack damage multiplier     |
| `pal_damage_rate_defense`         | float | `1.0`   | Pal defense damage multiplier    |
| `pal_stomach_decrease_rate`       | float | `0.4`   | Pal hunger decrease rate         |
| `pal_stamina_decrease_rate`       | float | `0.25`  | Pal stamina decrease rate        |
| `pal_auto_hp_regen_rate`          | float | `1.0`   | Pal HP regen rate                |
| `pal_auto_hp_regen_rate_in_sleep` | float | `1.0`   | Pal HP regen rate while sleeping |

### 🏠 Base / Building

| Option                                    | Type  | Default | Description                          |
|-------------------------------------------|-------|---------|--------------------------------------|
| `build_object_damage_rate`                | float | `1.0`   | Building damage rate                 |
| `build_object_deterioration_damage_rate`  | float | `0.5`   | Building deterioration rate          |
| `base_camp_max_num`                       | int   | `128`   | Max number of base camps             |
| `base_camp_worker_max_num`                | int   | `30`    | Max workers per base camp            |
| `base_camp_max_num_in_guild`              | int   | `6`     | Max base camps per guild             |

### 📦 Items / Collection

| Option                                | Type  | Default | Description                        |
|---------------------------------------|-------|---------|------------------------------------|
| `collection_drop_rate`                | float | `2.5`   | Collection drop rate               |
| `collection_object_hp_rate`           | float | `0.5`   | Collection object HP rate          |
| `collection_object_respawn_speed_rate`| float | `1.0`   | Collection respawn speed           |
| `enemy_drop_item_rate`                | float | `3.0`   | Enemy item drop rate               |
| `item_weight_rate`                    | float | `0.25`  | Item weight multiplier             |

### 🥚 Hatching / Work

| Option                          | Type  | Default | Description                  |
|---------------------------------|-------|---------|------------------------------|
| `pal_egg_default_hatching_time` | float | `0.2`   | Egg hatching time multiplier |
| `work_speed_rate`               | float | `2.0`   | Work speed rate              |

### ⚔️ Death / Combat

| Option                              | Type  | Default | Description                               |
|--------------------------------------|-------|---------|-------------------------------------------|
| `death_penalty`                      | string| `None`  | Death penalty (None/Item/ItemAndEquipment/All) |
| `enable_friendly_fire`               | bool  | `false` | Enable friendly fire                      |
| `enable_invader_enemy`               | bool  | `true`  | Enable raid events                        |
| `enable_defense_other_guild_player`  | bool  | `false` | Enable defense against other guild players|
| `enable_player_to_player_damage`     | bool  | `false` | Enable PvP damage                         |

### 👥 Multiplayer

| Option                       | Type | Default | Description                           |
|------------------------------|------|---------|---------------------------------------|
| `is_multiplay`               | bool | `false` | Enable multiplayer mode               |
| `is_pvp`                     | bool | `false` | Enable PvP mode                       |
| `coop_player_max_num`        | int  | `4`     | Max co-op players in a group          |
| `exist_player_after_logout`  | bool | `false` | Player character persists after logout|
| `supply_drop_span`           | int  | `80`    | Supply drop interval (minutes)        |

### 🔧 Misc

| Option                    | Type  | Default | Description                  |
|---------------------------|-------|---------|------------------------------|
| `enable_fast_travel`      | bool  | `true`  | Enable fast travel           |
| `auto_save_span`          | float | `30.0`  | Auto-save interval (minutes) |
| `is_use_backup_save_data` | bool  | `true`  | Enable backup saves          |
| `log_format_type`         | string| `Text`  | Log format type              |

### 💬 Discord Webhooks

Send notifications to a Discord channel when the server updates, comes online, shuts down, or when players join/leave.

| Option                              | Type   | Default                      | Description                                      |
|--------------------------------------|--------|------------------------------|--------------------------------------------------|
| `discord_webhook_url`                | string | *(empty)*                    | Discord webhook URL (paste from Discord channel settings) |
| `discord_pre_update_boot_message`    | string | `Server is updating...`      | Message sent when server starts updating         |
| `discord_post_update_boot_message`   | string | `Server is back online.`     | Message sent when server is online               |
| `discord_pre_shutdown_message`       | string | `Server is shutting down...` | Message sent when server is shutting down         |
| `discord_player_join_message`        | string | `🟢 \`player_name\` joined` | Message template for player joins (use `player_name` as placeholder) |
| `discord_player_leave_message`       | string | `🔴 \`player_name\` left`   | Message template for player leaves               |
| `discord_player_join_enabled`        | bool   | `true`                       | Enable player join notifications                 |
| `discord_player_leave_enabled`       | bool   | `true`                       | Enable player leave notifications                |
| `discord_suppress_notifications`     | bool   | `true`                       | Suppress @everyone / notification sounds          |

> **Note:** Player join/leave notifications require `rcon_enabled: true` and a valid `admin_password`. The add-on polls the server via RCON every 15 seconds to detect player changes.

#### How to set up Discord webhooks:
1. In Discord, go to your channel → **Edit Channel → Integrations → Webhooks**
2. Create a new webhook and copy the URL
3. Paste it into `discord_webhook_url` in the add-on Configuration tab

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

## 🌐 Network Ports

| Port  | Protocol | Description  |
|-------|----------|--------------|
| 8211  | UDP      | Game server  |
| 27015 | UDP      | Query port   |
| 25575 | TCP      | RCON port    |

Make sure these ports are forwarded on your router if you want external players to join **without** Tailscale.

> 💡 **With Tailscale enabled**, players on your Tailnet can connect directly using the Tailscale IP — **no port forwarding required!**

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

## 🔄 Migrating from Docker Compose

If you were previously using `thijsvanloef/palworld-server-docker`, all your environment variables map 1:1 to the HA add-on options:

| Docker Compose `environment:`          | HA Add-on Option                       |
|----------------------------------------|----------------------------------------|
| `SERVER_NAME`                          | `server_name`                          |
| `SERVER_PASSWORD`                      | `server_password`                      |
| `ADMIN_PASSWORD`                       | `admin_password`                       |
| `PLAYERS`                              | `server_player_max_num`                |
| `DIFFICULTY`                           | `difficulty`                           |
| `EXP_RATE`                             | `exp_rate`                             |
| `DEATH_PENALTY`                        | `death_penalty`                        |
| `DISCORD_WEBHOOK_URL`                  | `discord_webhook_url`                  |
| `DISCORD_PLAYER_JOIN_MESSAGE`          | `discord_player_join_message`          |
| `DISCORD_PLAYER_LEAVE_MESSAGE`         | `discord_player_leave_message`         |
| `DISCORD_PLAYER_JOIN_MESSAGE_ENABLED`  | `discord_player_join_enabled`          |
| `DISCORD_PLAYER_LEAVE_MESSAGE_ENABLED` | `discord_player_leave_enabled`         |
| `DISCORD_SUPPRESS_NOTIFICATIONS`       | `discord_suppress_notifications`       |
| *(all other settings)*                 | *(same name, lowercase with underscores)* |

> **Your existing save data:** Copy your `palworld/` folder contents to `/share/palworld/server/` on your HA host to keep your world.

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
