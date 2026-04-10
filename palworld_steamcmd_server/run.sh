#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"

# SteamCMD stays in the container (executable!)
STEAMCMD="/opt/steamcmd/steamcmd.sh"

# All persistent data on host (/share)
BASE="/share/palworld"
SERVER_DIR="${BASE}/server"
CONFIG_DIR="${BASE}/config"
STEAM_HOME="${BASE}/steam_home"
INI_FILE="${CONFIG_DIR}/PalWorldSettings.ini"
GAME_CFG_DIR="${SERVER_DIR}/Pal/Saved/Config/LinuxServer"
TS_STATE_DIR="/share/palworld/tailscale"

echo "▶ Palworld Add-on starting (SteamCMD exec from /opt, data in /share)…"

if [[ ! -f "${OPTIONS_FILE}" ]]; then
  echo "❌ options.json not found: ${OPTIONS_FILE}"
  exit 1
fi

# Debug: show options.json with secrets redacted
echo "▶ DEBUG: options.json contents (secrets redacted):"
jq '{
  app_id, steam_user, update_on_boot,
  server_name, server_description, server_player_max_num, port, query_port,
  multithreading, community_server, crossplay_platforms,
  rcon_enabled, rcon_port,
  daytime_speedrate, nighttime_speedrate, exp_rate, pal_capture_rate,
  pal_spawn_num_rate, difficulty,
  player_damage_rate_attack, player_damage_rate_defense,
  player_stomach_decrease_rate, player_stamina_decrease_rate,
  player_auto_hp_regen_rate, player_auto_hp_regen_rate_in_sleep,
  pal_damage_rate_attack, pal_damage_rate_defense,
  pal_stomach_decrease_rate, pal_stamina_decrease_rate,
  pal_auto_hp_regen_rate, pal_auto_hp_regen_rate_in_sleep,
  build_object_damage_rate, build_object_deterioration_damage_rate,
  base_camp_max_num, base_camp_worker_max_num, base_camp_max_num_in_guild,
  collection_drop_rate, collection_object_hp_rate, collection_object_respawn_speed_rate,
  enemy_drop_item_rate, item_weight_rate,
  pal_egg_default_hatching_time, work_speed_rate,
  death_penalty, enable_friendly_fire, enable_invader_enemy,
  enable_defense_other_guild_player, enable_player_to_player_damage,
  is_multiplay, is_pvp, coop_player_max_num, exist_player_after_logout, supply_drop_span,
  enable_fast_travel, auto_save_span, is_use_backup_save_data, log_format_type,
  discord_player_join_enabled, discord_player_leave_enabled, discord_suppress_notifications,
  tailscale_enabled, tailscale_hostname, tailscale_accept_dns,
  tailscale_advertise_exit_node, tailscale_serve_enabled, tailscale_serve_port, tailscale_funnel,
  discord_webhook_url: (if .discord_webhook_url == "" then "(empty)" else "***REDACTED***" end),
  tailscale_authkey: (if .tailscale_authkey == "" then "(empty)" else "***REDACTED***" end),
  steam_pass: (if .steam_pass == "" then "(empty)" else "***REDACTED***" end),
  server_password: (if .server_password == "" then "(empty)" else "***REDACTED***" end),
  admin_password: (if .admin_password == "" then "(empty)" else "***REDACTED***" end)
}' "${OPTIONS_FILE}"
echo ""

# ────────────────────────────────────────────
# Read all options from HA config UI
# ────────────────────────────────────────────

# Helper: read a string/number option with a default (default handled in bash, NOT jq)
opt() {
  local val
  val=$(jq -r ".$1 // empty" "${OPTIONS_FILE}")
  if [[ -z "${val}" ]]; then
    echo "$2"
  else
    echo "${val}"
  fi
}
# Helper: read a boolean option as "true"/"false"
optb() { jq -r "if .$1 then \"true\" else \"false\" end" "${OPTIONS_FILE}"; }

# ── SteamCMD ──
APP_ID="$(opt app_id '')"
STEAM_USER="$(opt steam_user 'anonymous')"
STEAM_PASS="$(opt steam_pass '')"
UPDATE_ON_BOOT="$(optb update_on_boot)"

# ── Server Settings ──
SERVER_NAME="$(opt server_name 'Palworld Server')"
SERVER_DESCRIPTION="$(opt server_description '')"
SERVER_PASSWORD="$(opt server_password '')"
ADMIN_PASSWORD="$(opt admin_password '')"
SERVER_PLAYER_MAX_NUM="$(opt server_player_max_num 32)"
GAME_PORT="$(opt port 8211)"
QUERY_PORT="$(opt query_port 27015)"
MULTITHREADING="$(optb multithreading)"
COMMUNITY_SERVER="$(optb community_server)"
CROSSPLAY_PLATFORMS="$(opt crossplay_platforms 'Steam,Xbox,PS5,Mac')"

# ── RCON ──
RCON_ENABLED="$(optb rcon_enabled)"
RCON_PORT="$(opt rcon_port 25575)"

# ── Gameplay Rates ──
DAYTIME_SPEEDRATE="$(opt daytime_speedrate 1.0)"
NIGHTTIME_SPEEDRATE="$(opt nighttime_speedrate 1.0)"
EXP_RATE="$(opt exp_rate 1.0)"
PAL_CAPTURE_RATE="$(opt pal_capture_rate 1.0)"
PAL_SPAWN_NUM_RATE="$(opt pal_spawn_num_rate 1.0)"
DIFFICULTY="$(opt difficulty 'Normal')"

# ── Player Settings ──
PLAYER_DAMAGE_RATE_ATTACK="$(opt player_damage_rate_attack 1.0)"
PLAYER_DAMAGE_RATE_DEFENSE="$(opt player_damage_rate_defense 1.0)"
PLAYER_STOMACH_DECREASE_RATE="$(opt player_stomach_decrease_rate 1.0)"
PLAYER_STAMINA_DECREASE_RATE="$(opt player_stamina_decrease_rate 1.0)"
PLAYER_AUTO_HP_REGEN_RATE="$(opt player_auto_hp_regen_rate 1.0)"
PLAYER_AUTO_HP_REGEN_RATE_IN_SLEEP="$(opt player_auto_hp_regen_rate_in_sleep 1.0)"

# ── Pal Settings ──
PAL_DAMAGE_RATE_ATTACK="$(opt pal_damage_rate_attack 1.0)"
PAL_DAMAGE_RATE_DEFENSE="$(opt pal_damage_rate_defense 1.0)"
PAL_STOMACH_DECREASE_RATE="$(opt pal_stomach_decrease_rate 1.0)"
PAL_STAMINA_DECREASE_RATE="$(opt pal_stamina_decrease_rate 1.0)"
PAL_AUTO_HP_REGEN_RATE="$(opt pal_auto_hp_regen_rate 1.0)"
PAL_AUTO_HP_REGEN_RATE_IN_SLEEP="$(opt pal_auto_hp_regen_rate_in_sleep 1.0)"

# ── Base / Building ──
BUILD_OBJECT_DAMAGE_RATE="$(opt build_object_damage_rate 1.0)"
BUILD_OBJECT_DETERIORATION_DAMAGE_RATE="$(opt build_object_deterioration_damage_rate 1.0)"
BASE_CAMP_MAX_NUM="$(opt base_camp_max_num 128)"
BASE_CAMP_WORKER_MAX_NUM="$(opt base_camp_worker_max_num 15)"
BASE_CAMP_MAX_NUM_IN_GUILD="$(opt base_camp_max_num_in_guild 4)"

# ── Items / Collection ──
COLLECTION_DROP_RATE="$(opt collection_drop_rate 1.0)"
COLLECTION_OBJECT_HP_RATE="$(opt collection_object_hp_rate 1.0)"
COLLECTION_OBJECT_RESPAWN_SPEED_RATE="$(opt collection_object_respawn_speed_rate 1.0)"
ENEMY_DROP_ITEM_RATE="$(opt enemy_drop_item_rate 1.0)"
ITEM_WEIGHT_RATE="$(opt item_weight_rate 1.0)"

# ── Hatching / Work ──
PAL_EGG_DEFAULT_HATCHING_TIME="$(opt pal_egg_default_hatching_time 72.0)"
WORK_SPEED_RATE="$(opt work_speed_rate 1.0)"

# ── Death / Combat ──
DEATH_PENALTY="$(opt death_penalty 'All')"
ENABLE_FRIENDLY_FIRE="$(optb enable_friendly_fire)"
ENABLE_INVADER_ENEMY="$(optb enable_invader_enemy)"
ENABLE_DEFENSE_OTHER_GUILD_PLAYER="$(optb enable_defense_other_guild_player)"
ENABLE_PLAYER_TO_PLAYER_DAMAGE="$(optb enable_player_to_player_damage)"

# ── Multiplayer ──
IS_MULTIPLAY="$(optb is_multiplay)"
IS_PVP="$(optb is_pvp)"
COOP_PLAYER_MAX_NUM="$(opt coop_player_max_num 4)"
EXIST_PLAYER_AFTER_LOGOUT="$(optb exist_player_after_logout)"
SUPPLY_DROP_SPAN="$(opt supply_drop_span 180)"

# ── Misc ──
ENABLE_FAST_TRAVEL="$(optb enable_fast_travel)"
AUTO_SAVE_SPAN="$(opt auto_save_span 30.0)"
IS_USE_BACKUP_SAVE_DATA="$(optb is_use_backup_save_data)"
LOG_FORMAT_TYPE="$(opt log_format_type 'Text')"

# ── Discord Webhooks ──
DISCORD_WEBHOOK_URL="$(opt discord_webhook_url '')"
DISCORD_PRE_UPDATE_BOOT_MESSAGE="$(opt discord_pre_update_boot_message 'Server is updating...')"
DISCORD_POST_UPDATE_BOOT_MESSAGE="$(opt discord_post_update_boot_message 'Server is back online.')"
DISCORD_PRE_SHUTDOWN_MESSAGE="$(opt discord_pre_shutdown_message 'Server is shutting down...')"
DISCORD_PLAYER_JOIN_MESSAGE="$(opt discord_player_join_message 'player_name joined')"
DISCORD_PLAYER_LEAVE_MESSAGE="$(opt discord_player_leave_message 'player_name left')"
DISCORD_PLAYER_JOIN_ENABLED="$(optb discord_player_join_enabled)"
DISCORD_PLAYER_LEAVE_ENABLED="$(optb discord_player_leave_enabled)"
DISCORD_SUPPRESS_NOTIFICATIONS="$(optb discord_suppress_notifications)"

# ── Tailscale ──
TS_ENABLED="$(optb tailscale_enabled)"
TS_AUTHKEY="$(opt tailscale_authkey '')"
TS_HOSTNAME="$(opt tailscale_hostname 'palworld')"
TS_ACCEPT_DNS="$(optb tailscale_accept_dns)"
TS_ADVERTISE_EXIT="$(optb tailscale_advertise_exit_node)"
TS_SERVE_ENABLED="$(optb tailscale_serve_enabled)"
TS_SERVE_PORT="$(opt tailscale_serve_port 8212)"
TS_FUNNEL="$(optb tailscale_funnel)"

# Auto-enable Tailscale if an auth key is provided but the toggle was left off
if [[ "${TS_ENABLED}" != "true" && -n "${TS_AUTHKEY}" && "${TS_AUTHKEY}" != "null" ]]; then
  echo "▶ Tailscale: Auth key detected but tailscale_enabled is false — auto-enabling Tailscale."
  TS_ENABLED="true"
fi

echo "▶ Tailscale config: enabled=${TS_ENABLED} hostname=${TS_HOSTNAME} serve=${TS_SERVE_ENABLED} funnel=${TS_FUNNEL} authkey_set=$([ -n "${TS_AUTHKEY}" ] && echo 'yes' || echo 'no')"

if [[ -z "${APP_ID}" || "${APP_ID}" == "null" ]]; then
  echo "❌ app_id is missing"
  exit 1
fi

mkdir -p "${BASE}" "${SERVER_DIR}" "${CONFIG_DIR}" "${STEAM_HOME}" "${GAME_CFG_DIR}"
chown -R steam:steam "${BASE}" || true
chown -R steam:steam /opt/steamcmd || true
chmod +x "${STEAMCMD}" || true

# ────────────────────────────────────────────
# Discord Webhook Helper
# ────────────────────────────────────────────
send_discord_message() {
  local message="$1"
  if [[ -z "${DISCORD_WEBHOOK_URL}" || "${DISCORD_WEBHOOK_URL}" == "null" ]]; then
    return 0
  fi
  local flags=0
  if [[ "${DISCORD_SUPPRESS_NOTIFICATIONS}" == "true" ]]; then
    flags=4096
  fi
  local payload
  payload=$(jq -nc --arg content "${message}" --argjson flags "${flags}" \
    '{content: $content, flags: $flags}')
  curl -s -o /dev/null -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${DISCORD_WEBHOOK_URL}" || echo "⚠️ Discord webhook failed"
}

# ────────────────────────────────────────────
# Tailscale Setup
# ────────────────────────────────────────────
TAILSCALED_PID=""

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

  # Start tailscaled daemon in background (userspace networking as fallback)
  echo "▶ Tailscale: Starting tailscaled..."
  tailscaled \
    --state="${TS_STATE_DIR}/tailscaled.state" \
    --socket=/var/run/tailscale/tailscaled.sock \
    --tun=userspace-networking \
    2>&1 &
  TAILSCALED_PID=$!
  echo "▶ Tailscale: tailscaled started with PID ${TAILSCALED_PID}"

  # Wait for the socket to become available
  echo "▶ Tailscale: Waiting for daemon socket..."
  local waited=0
  for i in $(seq 1 30); do
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
  if [[ -z "${TS_AUTHKEY}" || "${TS_AUTHKEY}" == "null" ]]; then
    echo "⚠️  Tailscale is enabled but no auth key provided. Skipping Tailscale setup."
    echo "   Generate a key at: https://login.tailscale.com/admin/settings/keys"
  else
    start_tailscale || echo "⚠️  Tailscale setup failed, continuing without it..."
  fi
else
  echo "ℹ️  Tailscale is disabled. Set tailscale_enabled=true in the add-on config to use it."
fi

# ────────────────────────────────────────────
# SteamCMD / Palworld Install
# ────────────────────────────────────────────

steam_update() {
  local login_args=(+login "${STEAM_USER}")
  if [[ "${STEAM_USER}" != "anonymous" && -n "${STEAM_PASS}" ]]; then
    login_args=(+login "${STEAM_USER}" "${STEAM_PASS}")
  fi

  gosu steam:steam env HOME="${STEAM_HOME}" "${STEAMCMD}" \
    +force_install_dir "${SERVER_DIR}" \
    "${login_args[@]}" \
    +app_update "${APP_ID}" validate \
    +quit
}

if [[ "${UPDATE_ON_BOOT}" == "true" ]]; then
  echo "▶ SteamCMD: Install/Update Palworld to ${SERVER_DIR}"
  send_discord_message "${DISCORD_PRE_UPDATE_BOOT_MESSAGE}"
  steam_update
else
  echo "ℹ️ update_on_boot=false – skipping update"
fi

# ────────────────────────────────────────────
# Generate PalWorldSettings.ini from UI config
# ────────────────────────────────────────────

# Convert bash "true"/"false" to Palworld INI "True"/"False"
bool_to_pal() { [[ "$1" == "true" ]] && echo "True" || echo "False"; }

echo "▶ Generating PalWorldSettings.ini from add-on configuration..."
echo "▶ DEBUG: BASE_CAMP_WORKER_MAX_NUM=${BASE_CAMP_WORKER_MAX_NUM}"

cat > "${INI_FILE}" <<EOFINI
[/Script/Pal.PalGameWorldSettings]
OptionSettings=(Difficulty=${DIFFICULTY},DayTimeSpeedRate=${DAYTIME_SPEEDRATE},NightTimeSpeedRate=${NIGHTTIME_SPEEDRATE},ExpRate=${EXP_RATE},PalCaptureRate=${PAL_CAPTURE_RATE},PalSpawnNumRate=${PAL_SPAWN_NUM_RATE},PalDamageRateAttack=${PAL_DAMAGE_RATE_ATTACK},PalDamageRateDefense=${PAL_DAMAGE_RATE_DEFENSE},PlayerDamageRateAttack=${PLAYER_DAMAGE_RATE_ATTACK},PlayerDamageRateDefense=${PLAYER_DAMAGE_RATE_DEFENSE},PlayerStomachDecreaceRate=${PLAYER_STOMACH_DECREASE_RATE},PlayerStaminaDecreaceRate=${PLAYER_STAMINA_DECREASE_RATE},PlayerAutoHPRegeneRate=${PLAYER_AUTO_HP_REGEN_RATE},PlayerAutoHpRegeneRateInSleep=${PLAYER_AUTO_HP_REGEN_RATE_IN_SLEEP},PalStomachDecreaceRate=${PAL_STOMACH_DECREASE_RATE},PalStaminaDecreaceRate=${PAL_STAMINA_DECREASE_RATE},PalAutoHPRegeneRate=${PAL_AUTO_HP_REGEN_RATE},PalAutoHpRegeneRateInSleep=${PAL_AUTO_HP_REGEN_RATE_IN_SLEEP},BuildObjectDamageRate=${BUILD_OBJECT_DAMAGE_RATE},BuildObjectDeteriorationDamageRate=${BUILD_OBJECT_DETERIORATION_DAMAGE_RATE},CollectionDropRate=${COLLECTION_DROP_RATE},CollectionObjectHpRate=${COLLECTION_OBJECT_HP_RATE},CollectionObjectRespawnSpeedRate=${COLLECTION_OBJECT_RESPAWN_SPEED_RATE},EnemyDropItemRate=${ENEMY_DROP_ITEM_RATE},DeathPenalty=${DEATH_PENALTY},bEnablePlayerToPlayerDamage=$(bool_to_pal "${ENABLE_PLAYER_TO_PLAYER_DAMAGE}"),bEnableFriendlyFire=$(bool_to_pal "${ENABLE_FRIENDLY_FIRE}"),bEnableInvaderEnemy=$(bool_to_pal "${ENABLE_INVADER_ENEMY}"),bActiveUNKO=False,bEnableAimAssistPad=True,bEnableAimAssistKeyboard=False,DropItemMaxNum=3000,DropItemMaxNum_UNKO=100,BaseCampMaxNum=${BASE_CAMP_MAX_NUM},BaseCampWorkerMaxNum=${BASE_CAMP_WORKER_MAX_NUM},DropItemAliveMaxHours=1.000000,bAutoResetGuildNoOnlinePlayers=False,AutoResetGuildTimeNoOnlinePlayers=72.000000,GuildPlayerMaxNum=20,BaseCampMaxNumInGuild=${BASE_CAMP_MAX_NUM_IN_GUILD},PalEggDefaultHatchingTime=${PAL_EGG_DEFAULT_HATCHING_TIME},WorkSpeedRate=${WORK_SPEED_RATE},AutoSaveSpan=${AUTO_SAVE_SPAN},bIsMultiplay=$(bool_to_pal "${IS_MULTIPLAY}"),bIsPvP=$(bool_to_pal "${IS_PVP}"),bCanPickupOtherGuildDeathPenaltyDrop=False,bEnableNonLoginPenalty=True,bEnableFastTravel=$(bool_to_pal "${ENABLE_FAST_TRAVEL}"),bIsStartLocationSelectByMap=True,bExistPlayerAfterLogout=$(bool_to_pal "${EXIST_PLAYER_AFTER_LOGOUT}"),bEnableDefenseOtherGuildPlayer=$(bool_to_pal "${ENABLE_DEFENSE_OTHER_GUILD_PLAYER}"),bInvisibleOtherGuildBaseCampAreaFX=False,CoopPlayerMaxNum=${COOP_PLAYER_MAX_NUM},ServerPlayerMaxNum=${SERVER_PLAYER_MAX_NUM},ServerName="${SERVER_NAME}",ServerDescription="${SERVER_DESCRIPTION}",AdminPassword="${ADMIN_PASSWORD}",ServerPassword="${SERVER_PASSWORD}",PublicPort=${GAME_PORT},PublicIP="",RCONEnabled=$(bool_to_pal "${RCON_ENABLED}"),RCONPort=${RCON_PORT},Region="",bUseAuth=True,BanListURL="https://api.palworldgame.com/api/banlist.txt",RESTAPIEnabled=False,RESTAPIPort=8212,bShowPlayerList=True,bIsUseBackupSaveData=$(bool_to_pal "${IS_USE_BACKUP_SAVE_DATA}"),LogFormatType=${LOG_FORMAT_TYPE},SupplyDropSpan=${SUPPLY_DROP_SPAN},bEnableCommunityServer=$(bool_to_pal "${COMMUNITY_SERVER}"),ItemWeightRate=${ITEM_WEIGHT_RATE},CrossplayPlatforms=(${CROSSPLAY_PLATFORMS}))
EOFINI

chown steam:steam "${INI_FILE}" || true
echo "✅ PalWorldSettings.ini generated"

# Force Palworld to re-read settings from INI on next boot
# (Palworld caches settings in WorldOption.sav which overrides the INI)
echo "▶ Removing cached WorldOption.sav so settings from INI are applied..."
find "${SERVER_DIR}/Pal/Saved/SaveGames" -name "WorldOption.sav" -delete 2>/dev/null || true

# Copy config into game directory
mkdir -p "${GAME_CFG_DIR}"
cp -f "${INI_FILE}" "${GAME_CFG_DIR}/PalWorldSettings.ini"
chown -R steam:steam "${SERVER_DIR}/Pal/Saved/Config" || true

# Verify the INI was written correctly
echo "▶ DEBUG: Generated INI contents (secrets redacted):"
echo "  ┌──────────────────────────────────────────────────────────"
# Pretty-print: one setting per line, redact secrets
sed 's/,/\n/g' "${GAME_CFG_DIR}/PalWorldSettings.ini" \
  | sed 's/OptionSettings=(/OptionSettings=(\n/' \
  | sed 's/)$/\n)/' \
  | sed -E 's/(AdminPassword=)"[^"]*"/\1"***REDACTED***"/' \
  | sed -E 's/(ServerPassword=)"[^"]*"/\1"***REDACTED***"/' \
  | sed -E 's/(discord_webhook_url=)"[^"]*"/\1"***REDACTED***"/i' \
  | sed -E 's|(https://discord\.com/api/webhooks/[^ "]*)|***REDACTED_WEBHOOK***|g' \
  | while IFS= read -r line; do
      echo "  │ ${line}"
    done
echo "  └──────────────────────────────────────────────────────────"
echo ""

# steamclient.so fix (if present)
if [[ -f "${SERVER_DIR}/linux64/steamclient.so" ]]; then
  mkdir -p "${SERVER_DIR}/Pal/Binaries/Linux"
  cp -f "${SERVER_DIR}/linux64/steamclient.so" \
        "${SERVER_DIR}/Pal/Binaries/Linux/steamclient.so" || true
fi

SERVER_SH="${SERVER_DIR}/PalServer.sh"
SERVER_BIN="${SERVER_DIR}/Pal/Binaries/Linux/PalServer-Linux-Shipping"

# ────────────────────────────────────────────
# RCON Player Monitor (Discord join/leave)
# ────────────────────────────────────────────
PLAYER_MONITOR_PID=""

start_player_monitor() {
  if [[ "${RCON_ENABLED}" != "true" ]]; then
    echo "ℹ️  RCON disabled – player join/leave Discord notifications won't work"
    return 0
  fi
  if [[ -z "${DISCORD_WEBHOOK_URL}" || "${DISCORD_WEBHOOK_URL}" == "null" ]]; then
    echo "ℹ️  No Discord webhook URL – skipping player monitor"
    return 0
  fi
  if [[ "${DISCORD_PLAYER_JOIN_ENABLED}" != "true" && "${DISCORD_PLAYER_LEAVE_ENABLED}" != "true" ]]; then
    echo "ℹ️  Player join/leave notifications disabled – skipping player monitor"
    return 0
  fi

  echo "▶ Starting RCON player monitor for Discord notifications..."

  (
    # Wait for server to be ready
    sleep 30

    local previous_players=""

    while true; do
      # Get current player list via RCON
      local current_players
      current_players=$(rcon -a "127.0.0.1:${RCON_PORT}" -p "${ADMIN_PASSWORD}" "ShowPlayers" 2>/dev/null || echo "")

      if [[ -n "${current_players}" ]]; then
        # Extract player names (skip header line, get first CSV field)
        local current_names
        current_names=$(echo "${current_players}" | tail -n +2 | cut -d',' -f1 | sort | grep -v '^$' || echo "")

        local previous_names
        previous_names=$(echo "${previous_players}" | tail -n +2 | cut -d',' -f1 | sort | grep -v '^$' || echo "")

        # Detect joins
        if [[ "${DISCORD_PLAYER_JOIN_ENABLED}" == "true" ]]; then
          local joined
          joined=$(comm -13 <(echo "${previous_names}") <(echo "${current_names}") || echo "")
          while IFS= read -r player; do
            if [[ -n "${player}" ]]; then
              local msg="${DISCORD_PLAYER_JOIN_MESSAGE//player_name/${player}}"
              echo "▶ Discord: Player joined: ${player}"
              send_discord_message "${msg}"
            fi
          done <<< "${joined}"
        fi

        # Detect leaves
        if [[ "${DISCORD_PLAYER_LEAVE_ENABLED}" == "true" ]]; then
          local left
          left=$(comm -23 <(echo "${previous_names}") <(echo "${current_names}") || echo "")
          while IFS= read -r player; do
            if [[ -n "${player}" ]]; then
              local msg="${DISCORD_PLAYER_LEAVE_MESSAGE//player_name/${player}}"
              echo "▶ Discord: Player left: ${player}"
              send_discord_message "${msg}"
            fi
          done <<< "${left}"
        fi

        previous_players="${current_players}"
      fi

      sleep 15
    done
  ) &
  PLAYER_MONITOR_PID=$!
  echo "✅ Player monitor started (PID ${PLAYER_MONITOR_PID})"
}

# ────────────────────────────────────────────
# Graceful shutdown
# ────────────────────────────────────────────
cleanup() {
  echo "▶ Shutting down..."

  # Send Discord shutdown message
  send_discord_message "${DISCORD_PRE_SHUTDOWN_MESSAGE}"

  # Stop player monitor
  if [[ -n "${PLAYER_MONITOR_PID}" ]]; then
    kill "${PLAYER_MONITOR_PID}" 2>/dev/null || true
    wait "${PLAYER_MONITOR_PID}" 2>/dev/null || true
  fi

  # Save via RCON before stopping (if RCON is available)
  if [[ "${RCON_ENABLED}" == "true" && -n "${ADMIN_PASSWORD}" ]]; then
    echo "▶ Sending save command via RCON..."
    rcon -a "127.0.0.1:${RCON_PORT}" -p "${ADMIN_PASSWORD}" "Save" 2>/dev/null || true
    sleep 5
    echo "▶ Sending shutdown command via RCON..."
    rcon -a "127.0.0.1:${RCON_PORT}" -p "${ADMIN_PASSWORD}" "Shutdown 10 Server_is_shutting_down" 2>/dev/null || true
    sleep 12
  fi

  # Stop Tailscale
  if [[ -n "${TAILSCALED_PID}" ]]; then
    echo "▶ Tailscale: Logging out..."
    tailscale down 2>/dev/null || true
    kill "${TAILSCALED_PID}" 2>/dev/null || true
    wait "${TAILSCALED_PID}" 2>/dev/null || true
  fi

  # Stop server
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
}
trap cleanup SIGTERM SIGINT

# ────────────────────────────────────────────
# Start Palworld Server
# ────────────────────────────────────────────

# Build server launch arguments
LAUNCH_ARGS=(
  "-port=${GAME_PORT}"
  "-queryport=${QUERY_PORT}"
  "-useperfthreads"
  "-NoAsyncLoadingThread"
  "-UseMultithreadForDS"
)

# Add community server flag
if [[ "${COMMUNITY_SERVER}" == "true" ]]; then
  LAUNCH_ARGS+=("-publiclobby")
fi

echo "▶ Starting Palworld Server…"
echo "  Server Name: ${SERVER_NAME}"
echo "  Game Port: ${GAME_PORT} | Query Port: ${QUERY_PORT} | RCON Port: ${RCON_PORT}"
echo "  Max Players: ${SERVER_PLAYER_MAX_NUM} | Difficulty: ${DIFFICULTY}"
echo "  RCON: ${RCON_ENABLED} | Community: ${COMMUNITY_SERVER}"
echo "  Discord Webhooks: $([ -n "${DISCORD_WEBHOOK_URL}" ] && echo 'enabled' || echo 'disabled')"

if [[ -x "${SERVER_SH}" ]]; then
  gosu steam:steam env HOME="${STEAM_HOME}" "${SERVER_SH}" \
    "${LAUNCH_ARGS[@]}" &
elif [[ -x "${SERVER_BIN}" ]]; then
  gosu steam:steam env HOME="${STEAM_HOME}" "${SERVER_BIN}" \
    "${LAUNCH_ARGS[@]}" &
else
  echo "❌ Palworld Server binary not found in ${SERVER_DIR}"
  exit 1
fi

SERVER_PID=$!
echo "✅ Palworld Server started (PID ${SERVER_PID})"

# Start player monitor for Discord join/leave (runs in background)
start_player_monitor

# Send "server online" Discord message after a short delay
(
  sleep 20
  send_discord_message "${DISCORD_POST_UPDATE_BOOT_MESSAGE}"
) &

wait "${SERVER_PID}"
