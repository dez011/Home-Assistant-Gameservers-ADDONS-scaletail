#!/usr/bin/env bash
# Home Assistant add-on wrapper around thijsvanloef/palworld-server-docker.
# Reads /data/options.json, exports the matching upstream env vars,
# optionally brings up Tailscale, then hands off to the upstream entrypoint
# which handles SteamCMD install/update, settings generation, RCON,
# Discord notifications, backups and graceful shutdown.
set -uo pipefail

OPTIONS_FILE="/data/options.json"
SERVER_DIR="/share/palworld/server"
TS_STATE_DIR="/share/palworld/tailscale"
UPSTREAM_INIT="/home/steam/server/init.sh"

opt() { jq -r --arg k "$1" 'if .[$k] == null then "" else (.[$k] | tostring) end' "${OPTIONS_FILE}"; }

# Export env var $2 from option $1; empty options are skipped so upstream defaults apply
map_opt() {
  local val
  val="$(opt "$1")"
  if [[ -n "${val}" ]]; then
    export "$2=${val}"
  fi
}

echo "▶ Palworld Add-on starting (base: thijsvanloef/palworld-server-docker)…"

# ────────────────────────────────────────────
# Persistent data: upstream expects /palworld, we keep it on /share
# (server files, saves and backups all live under /share/palworld/server)
# ────────────────────────────────────────────
mkdir -p "${SERVER_DIR}"
if [[ -e /palworld && ! -L /palworld ]]; then
  rm -rf /palworld
fi
ln -sfn "${SERVER_DIR}" /palworld

# ── SteamCMD / updates ──
APP_ID="$(opt app_id)"
if [[ -n "${APP_ID}" && "${APP_ID}" != "2394010" ]]; then
  echo "⚠️  app_id=${APP_ID} is ignored — the base image always installs Palworld (2394010)."
fi
STEAM_USER="$(opt steam_user)"
if [[ -n "${STEAM_USER}" && "${STEAM_USER}" != "anonymous" ]]; then
  export STEAM_USERNAME="${STEAM_USER}"
  map_opt steam_pass STEAM_PASSWORD
fi
map_opt update_on_boot UPDATE_ON_BOOT
map_opt auto_update_enabled AUTO_UPDATE_ENABLED

# ── Server settings ──
map_opt server_name SERVER_NAME
map_opt server_description SERVER_DESCRIPTION
map_opt server_password SERVER_PASSWORD
map_opt admin_password ADMIN_PASSWORD
map_opt server_player_max_num PLAYERS
map_opt port PORT
map_opt query_port QUERY_PORT
map_opt multithreading MULTITHREADING
map_opt community_server COMMUNITY

# Upstream drops this raw into the INI, which needs a parenthesized list:
# CrossplayPlatforms=(Steam,Xbox,PS5,Mac)
CROSSPLAY_VAL="$(opt crossplay_platforms)"
if [[ -n "${CROSSPLAY_VAL}" ]]; then
  if [[ "${CROSSPLAY_VAL}" != \(* ]]; then
    CROSSPLAY_VAL="(${CROSSPLAY_VAL})"
  fi
  export CROSSPLAY_PLATFORMS="${CROSSPLAY_VAL}"
fi

# ── RCON / REST API ──
map_opt rcon_enabled RCON_ENABLED
map_opt rcon_port RCON_PORT
map_opt rest_api_enabled REST_API_ENABLED

# ── Backups (upstream supercronic) ──
map_opt backup_enabled BACKUP_ENABLED
map_opt backup_cron_expression BACKUP_CRON_EXPRESSION

# ── Gameplay rates ──
map_opt daytime_speedrate DAYTIME_SPEEDRATE
map_opt nighttime_speedrate NIGHTTIME_SPEEDRATE
map_opt exp_rate EXP_RATE
map_opt pal_capture_rate PAL_CAPTURE_RATE
map_opt pal_spawn_num_rate PAL_SPAWN_NUM_RATE

# The game (and upstream) call the hardest difficulty "Difficult";
# older versions of this add-on used "Hard"
DIFFICULTY_VAL="$(opt difficulty)"
if [[ "${DIFFICULTY_VAL}" == "Hard" ]]; then
  DIFFICULTY_VAL="Difficult"
fi
if [[ -n "${DIFFICULTY_VAL}" ]]; then
  export DIFFICULTY="${DIFFICULTY_VAL}"
fi

# ── Player settings ──
map_opt player_damage_rate_attack PLAYER_DAMAGE_RATE_ATTACK
map_opt player_damage_rate_defense PLAYER_DAMAGE_RATE_DEFENSE
map_opt player_stomach_decrease_rate PLAYER_STOMACH_DECREASE_RATE
map_opt player_stamina_decrease_rate PLAYER_STAMINA_DECREASE_RATE
map_opt player_auto_hp_regen_rate PLAYER_AUTO_HP_REGEN_RATE
map_opt player_auto_hp_regen_rate_in_sleep PLAYER_AUTO_HP_REGEN_RATE_IN_SLEEP

# ── Pal settings ──
map_opt pal_damage_rate_attack PAL_DAMAGE_RATE_ATTACK
map_opt pal_damage_rate_defense PAL_DAMAGE_RATE_DEFENSE
map_opt pal_stomach_decrease_rate PAL_STOMACH_DECREASE_RATE
map_opt pal_stamina_decrease_rate PAL_STAMINA_DECREASE_RATE
map_opt pal_auto_hp_regen_rate PAL_AUTO_HP_REGEN_RATE
map_opt pal_auto_hp_regen_rate_in_sleep PAL_AUTO_HP_REGEN_RATE_IN_SLEEP

# ── Base / building ──
map_opt build_object_damage_rate BUILD_OBJECT_DAMAGE_RATE
map_opt build_object_deterioration_damage_rate BUILD_OBJECT_DETERIORATION_DAMAGE_RATE
map_opt base_camp_max_num BASE_CAMP_MAX_NUM
map_opt base_camp_worker_max_num BASE_CAMP_WORKER_MAX_NUM
map_opt base_camp_max_num_in_guild BASE_CAMP_MAX_NUM_IN_GUILD

# ── Items / collection ──
map_opt collection_drop_rate COLLECTION_DROP_RATE
map_opt collection_object_hp_rate COLLECTION_OBJECT_HP_RATE
map_opt collection_object_respawn_speed_rate COLLECTION_OBJECT_RESPAWN_SPEED_RATE
map_opt enemy_drop_item_rate ENEMY_DROP_ITEM_RATE
map_opt item_weight_rate ITEM_WEIGHT_RATE

# ── Hatching / work ──
map_opt pal_egg_default_hatching_time PAL_EGG_DEFAULT_HATCHING_TIME
map_opt work_speed_rate WORK_SPEED_RATE

# ── Death / combat ──
map_opt death_penalty DEATH_PENALTY
map_opt enable_friendly_fire ENABLE_FRIENDLY_FIRE
map_opt enable_invader_enemy ENABLE_INVADER_ENEMY
map_opt enable_defense_other_guild_player ENABLE_DEFENSE_OTHER_GUILD_PLAYER
map_opt enable_player_to_player_damage ENABLE_PLAYER_TO_PLAYER_DAMAGE

# ── Multiplayer ──
map_opt is_multiplay IS_MULTIPLAY
map_opt is_pvp IS_PVP
map_opt coop_player_max_num COOP_PLAYER_MAX_NUM
map_opt exist_player_after_logout EXIST_PLAYER_AFTER_LOGOUT
map_opt supply_drop_span SUPPLY_DROP_SPAN

# ── Misc ──
map_opt enable_fast_travel ENABLE_FAST_TRAVEL
map_opt auto_save_span AUTO_SAVE_SPAN
map_opt is_use_backup_save_data USE_BACKUP_SAVE_DATA
map_opt log_format_type LOG_FORMAT_TYPE

# ── Discord webhooks ──
map_opt discord_webhook_url DISCORD_WEBHOOK_URL
map_opt discord_pre_update_boot_message DISCORD_PRE_UPDATE_BOOT_MESSAGE
map_opt discord_post_update_boot_message DISCORD_POST_UPDATE_BOOT_MESSAGE
map_opt discord_pre_shutdown_message DISCORD_PRE_SHUTDOWN_MESSAGE
map_opt discord_player_join_message DISCORD_PLAYER_JOIN_MESSAGE
map_opt discord_player_leave_message DISCORD_PLAYER_LEAVE_MESSAGE
map_opt discord_player_join_enabled DISCORD_PLAYER_JOIN_MESSAGE_ENABLED
map_opt discord_player_leave_enabled DISCORD_PLAYER_LEAVE_MESSAGE_ENABLED
map_opt discord_suppress_notifications DISCORD_SUPPRESS_NOTIFICATIONS

# Upstream drops privileges to this UID/GID itself
export PUID=1000
export PGID=1000

# ────────────────────────────────────────────
# Tailscale (optional)
# ────────────────────────────────────────────
TS_ENABLED="$(opt tailscale_enabled)"
TS_AUTHKEY="$(opt tailscale_authkey)"
TS_HOSTNAME="$(opt tailscale_hostname)"
TS_HOSTNAME="${TS_HOSTNAME:-palworld}"
TS_ACCEPT_DNS="$(opt tailscale_accept_dns)"
TS_ADVERTISE_EXIT="$(opt tailscale_advertise_exit_node)"
TS_SERVE_ENABLED="$(opt tailscale_serve_enabled)"
TS_SERVE_PORT="$(opt tailscale_serve_port)"
TS_FUNNEL="$(opt tailscale_funnel)"
GAME_PORT="${PORT:-8211}"

if [[ "${TS_ENABLED}" != "true" && -n "${TS_AUTHKEY}" ]]; then
  echo "▶ Tailscale: Auth key detected but tailscale_enabled is false — auto-enabling Tailscale."
  TS_ENABLED="true"
fi

start_tailscale() {
  echo "▶ Tailscale: Setting up..."

  # Ensure TUN device exists
  mkdir -p /dev/net
  if [[ ! -c /dev/net/tun ]]; then
    echo "▶ Tailscale: Creating /dev/net/tun..."
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
  fi

  # Persistent state
  mkdir -p "${TS_STATE_DIR}"
  mkdir -p /var/run/tailscale

  # Start tailscaled daemon in background.
  #
  # Palworld game traffic is UDP (port 8211). Tailscale's userspace networking
  # (netstack) CANNOT forward inbound UDP to a local server — it only exposes
  # TCP/HTTP via `tailscale serve`. With userspace mode you get log lines like
  #   netstack: UDP session between 127.0.0.1:xxxxx and 127.0.0.1:8211 timed out
  # and players can never connect to the game port.
  #
  # So use the real kernel TUN interface (tailscale0) whenever /dev/net/tun is
  # usable — then the node's tailnet IP is a real IP and inbound UDP:8211 is
  # delivered straight to the game server. Only fall back to userspace if the
  # TUN device genuinely can't be opened (in which case UDP will NOT work and we
  # say so loudly).
  local ts_tun_arg=""
  if [[ -c /dev/net/tun ]]; then
    echo "▶ Tailscale: /dev/net/tun present — using kernel networking (tailscale0); UDP game traffic supported."
  else
    echo "⚠️  Tailscale: /dev/net/tun unavailable — falling back to userspace-networking."
    echo "⚠️  Tailscale: inbound UDP (the Palworld game port) will NOT work in this mode."
    echo "⚠️  Tailscale: ensure the add-on has NET_ADMIN + SYS_MODULE and /dev/net/tun."
    ts_tun_arg="--tun=userspace-networking"
  fi

  echo "▶ Tailscale: Starting tailscaled..."
  tailscaled \
    --state="${TS_STATE_DIR}/tailscaled.state" \
    --socket=/var/run/tailscale/tailscaled.sock \
    ${ts_tun_arg} \
    2>&1 &
  echo "▶ Tailscale: tailscaled started with PID $!"

  # Wait for the socket to become available
  echo "▶ Tailscale: Waiting for daemon socket..."
  local waited=0
  for _ in $(seq 1 30); do
    if [[ -S /var/run/tailscale/tailscaled.sock ]]; then
      echo "▶ Tailscale: Socket ready after ${waited}s"
      break
    fi
    sleep 1
    waited=$((waited + 1))
  done

  if [[ ! -S /var/run/tailscale/tailscaled.sock ]]; then
    echo "❌ Tailscale: tailscaled did not start in time (waited ${waited}s)"
    echo "❌ Tailscale: Check if NET_ADMIN capability is available"
    return 1
  fi

  # Build tailscale up arguments
  local ts_args=("--hostname=${TS_HOSTNAME}" "--auth-key=${TS_AUTHKEY}" "--reset")

  if [[ "${TS_ACCEPT_DNS}" == "true" ]]; then
    ts_args+=("--accept-dns=true")
  else
    ts_args+=("--accept-dns=false")
  fi

  if [[ "${TS_ADVERTISE_EXIT}" == "true" ]]; then
    ts_args+=("--advertise-exit-node")
  fi

  echo "▶ Tailscale: Connecting to tailnet as '${TS_HOSTNAME}'..."
  echo "▶ Tailscale: Running: tailscale up ${ts_args[*]//${TS_AUTHKEY}/tskey-***REDACTED***}"
  if ! tailscale up "${ts_args[@]}" 2>&1; then
    echo "❌ Tailscale: 'tailscale up' failed"
    return 1
  fi

  # Show assigned IP
  local ts_ip
  ts_ip="$(tailscale ip -4 2>/dev/null || echo 'unknown')"
  echo "✅ Tailscale: Connected! Tailscale IP: ${ts_ip}"
  echo "   Players on your Tailnet can connect to: ${ts_ip}:${GAME_PORT}"
  echo "   (or ${TS_HOSTNAME}:${GAME_PORT} if using MagicDNS)"

  # Show tailscale status for debugging
  echo "▶ Tailscale status:"
  tailscale status 2>&1 || true

  # ── Tailscale Serve Configuration ──
  if [[ "${TS_SERVE_ENABLED}" == "true" ]]; then
    echo "▶ Tailscale Serve: Configuring proxy on port ${TS_SERVE_PORT}..."

    # Reset any existing serve config
    tailscale serve reset 2>/dev/null || true

    # Use tailscale serve/funnel CLI to proxy HTTPS -> local port
    if [[ "${TS_FUNNEL}" == "true" ]]; then
      echo "▶ Tailscale Funnel: Exposing port ${TS_SERVE_PORT} to the internet..."
      tailscale funnel --bg --https 443 "http://localhost:${TS_SERVE_PORT}" 2>&1 || {
        echo "⚠️  Tailscale Funnel --bg failed, trying without --bg..."
        tailscale funnel --https 443 --set-path / "http://localhost:${TS_SERVE_PORT}" 2>&1 &
      }
    else
      echo "▶ Tailscale Serve: Exposing port ${TS_SERVE_PORT} on your Tailnet..."
      tailscale serve --bg --https 443 "http://localhost:${TS_SERVE_PORT}" 2>&1 || {
        echo "⚠️  Tailscale Serve --bg failed, trying without --bg..."
        tailscale serve --https 443 --set-path / "http://localhost:${TS_SERVE_PORT}" 2>&1 &
      }
    fi

    echo "✅ Tailscale Serve: HTTPS proxy active for port ${TS_SERVE_PORT}"
  fi
}

if [[ "${TS_ENABLED}" == "true" ]]; then
  if [[ -z "${TS_AUTHKEY}" ]]; then
    echo "⚠️  Tailscale is enabled but no auth key provided. Skipping Tailscale setup."
    echo "   Generate a key at: https://login.tailscale.com/admin/settings/keys"
  else
    start_tailscale || echo "⚠️  Tailscale setup failed, continuing without it..."
  fi
else
  echo "ℹ️  Tailscale is disabled. Set tailscale_enabled=true in the add-on config to use it."
fi

# ────────────────────────────────────────────
# Hand off to upstream (SteamCMD update, settings, RCON, Discord, server)
# ────────────────────────────────────────────
echo "▶ Handing off to ${UPSTREAM_INIT}"
exec "${UPSTREAM_INIT}"
