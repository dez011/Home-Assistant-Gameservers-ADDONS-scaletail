#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"

# SteamCMD bleibt im Container (ausführbar!)
STEAMCMD="/opt/steamcmd/steamcmd.sh"

# Alles Persistente auf den Host (/share)
BASE="/share/palworld"
SERVER_DIR="${BASE}/server"
CONFIG_DIR="${BASE}/config"
STEAM_HOME="${BASE}/steam_home"
INI_FILE="${CONFIG_DIR}/PalWorldSettings.ini"
GAME_CFG_DIR="${SERVER_DIR}/Pal/Saved/Config/LinuxServer"
TS_STATE_DIR="/share/palworld/tailscale"

GAME_PORT=8211
QUERY_PORT=27015

echo "▶ Palworld Add-on startet (SteamCMD exec aus /opt, Daten nach /share)…"

if [[ ! -f "${OPTIONS_FILE}" ]]; then
  echo "❌ options.json nicht gefunden: ${OPTIONS_FILE}"
  exit 1
fi

# Debug: show raw options.json content for troubleshooting
echo "▶ DEBUG: options.json contents:"
cat "${OPTIONS_FILE}"
echo ""

APP_ID="$(jq -r '.app_id // empty' "${OPTIONS_FILE}")"
STEAM_USER="$(jq -r '.steam_user // "anonymous"' "${OPTIONS_FILE}")"
STEAM_PASS="$(jq -r '.steam_pass // ""' "${OPTIONS_FILE}")"
UPDATE_ON_BOOT="$(jq -r 'if .update_on_boot then "true" else "false" end' "${OPTIONS_FILE}")"

# Tailscale options – use explicit if/then/else for booleans so JSON true/false map to string "true"/"false"
TS_ENABLED="$(jq -r 'if .tailscale_enabled then "true" else "false" end' "${OPTIONS_FILE}")"
TS_AUTHKEY="$(jq -r '.tailscale_authkey // ""' "${OPTIONS_FILE}")"
TS_HOSTNAME="$(jq -r '.tailscale_hostname // "palworld"' "${OPTIONS_FILE}")"
TS_ACCEPT_DNS="$(jq -r 'if .tailscale_accept_dns then "true" else "false" end' "${OPTIONS_FILE}")"
TS_ADVERTISE_EXIT="$(jq -r 'if .tailscale_advertise_exit_node then "true" else "false" end' "${OPTIONS_FILE}")"
TS_SERVE_ENABLED="$(jq -r 'if .tailscale_serve_enabled then "true" else "false" end' "${OPTIONS_FILE}")"
TS_SERVE_PORT="$(jq -r '.tailscale_serve_port // 8212' "${OPTIONS_FILE}")"
TS_FUNNEL="$(jq -r 'if .tailscale_funnel then "true" else "false" end' "${OPTIONS_FILE}")"

# Auto-enable Tailscale if an auth key is provided but the toggle was left off
if [[ "${TS_ENABLED}" != "true" && -n "${TS_AUTHKEY}" && "${TS_AUTHKEY}" != "null" ]]; then
  echo "▶ Tailscale: Auth key detected but tailscale_enabled is false — auto-enabling Tailscale."
  TS_ENABLED="true"
fi

echo "▶ Tailscale config: enabled=${TS_ENABLED} hostname=${TS_HOSTNAME} serve=${TS_SERVE_ENABLED} funnel=${TS_FUNNEL} authkey_set=$([ -n "${TS_AUTHKEY}" ] && echo 'yes' || echo 'no')"

if [[ -z "${APP_ID}" || "${APP_ID}" == "null" ]]; then
  echo "❌ app_id fehlt"
  exit 1
fi

mkdir -p "${BASE}" "${SERVER_DIR}" "${CONFIG_DIR}" "${STEAM_HOME}" "${GAME_CFG_DIR}"
chown -R steam:steam "${BASE}" || true
chown -R steam:steam /opt/steamcmd || true
chmod +x "${STEAMCMD}" || true

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
# SteamCMD / Palworld
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
  echo "▶ SteamCMD: Install/Update Palworld nach ${SERVER_DIR}"
  steam_update
else
  echo "ℹ️ update_on_boot=false – überspringe Update"
fi

# Default Config nur einmal erzeugen
if [[ ! -f "${INI_FILE}" ]]; then
  echo "▶ Erzeuge Default PalWorldSettings.ini unter /share"
  cat > "${INI_FILE}" <<'EOF'
[/Script/Pal.PalGameWorldSettings]
OptionSettings=(
  ServerName="Palworld Server",
  ServerDescription="",
  ServerPassword="",
  AdminPassword="",
  ServerPlayerMaxNum=32,
  DayTimeSpeedRate=1.0,
  NightTimeSpeedRate=1.0,
  ExpRate=1.0,
  PalSpawnNumRate=1.0,
  DeathPenalty="All",
  bEnableFastTravel=True,
  bEnableInvaderEnemy=True,
  bIsUseBackupSaveData=True,
  LogFormatType="Text"
)
EOF
  chown steam:steam "${INI_FILE}" || true
fi

# Config ins Spiel spiegeln
mkdir -p "${GAME_CFG_DIR}"
cp -f "${INI_FILE}" "${GAME_CFG_DIR}/PalWorldSettings.ini"
chown -R steam:steam "${SERVER_DIR}/Pal/Saved/Config" || true

# steamclient.so fix (falls vorhanden)
if [[ -f "${SERVER_DIR}/linux64/steamclient.so" ]]; then
  mkdir -p "${SERVER_DIR}/Pal/Binaries/Linux"
  cp -f "${SERVER_DIR}/linux64/steamclient.so" \
        "${SERVER_DIR}/Pal/Binaries/Linux/steamclient.so" || true
fi

SERVER_SH="${SERVER_DIR}/PalServer.sh"
SERVER_BIN="${SERVER_DIR}/Pal/Binaries/Linux/PalServer-Linux-Shipping"

# Graceful shutdown – stop Tailscale cleanly
cleanup() {
  echo "▶ Shutting down..."
  if [[ -n "${TAILSCALED_PID}" ]]; then
    echo "▶ Tailscale: Logging out..."
    tailscale down 2>/dev/null || true
    kill "${TAILSCALED_PID}" 2>/dev/null || true
    wait "${TAILSCALED_PID}" 2>/dev/null || true
  fi
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
}
trap cleanup SIGTERM SIGINT

echo "▶ Starte Palworld Server…"
if [[ -x "${SERVER_SH}" ]]; then
  gosu steam:steam env HOME="${STEAM_HOME}" "${SERVER_SH}" \
    -port="${GAME_PORT}" \
    -queryport="${QUERY_PORT}" \
    -useperfthreads \
    -NoAsyncLoadingThread \
    -UseMultithreadForDS &
elif [[ -x "${SERVER_BIN}" ]]; then
  gosu steam:steam env HOME="${STEAM_HOME}" "${SERVER_BIN}" \
    -port="${GAME_PORT}" \
    -queryport="${QUERY_PORT}" \
    -useperfthreads \
    -NoAsyncLoadingThread \
    -UseMultithreadForDS &
else
  echo "❌ Palworld Server Binary nicht gefunden in ${SERVER_DIR}"
  exit 1
fi

SERVER_PID=$!
wait "${SERVER_PID}"
