# Built on thijsvanloef/palworld-server-docker — it handles SteamCMD,
# server install/updates, RCON, Discord, backups and settings generation.
# We add Tailscale and translate HA add-on options into its env vars.
# v2 = upstream's rolling 2.x tag; picks up their fixes on every rebuild.
FROM thijsvanloef/palworld-server-docker:v2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Tailscale (base image is Debian trixie) + jq for /data/options.json
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl jq iptables iproute2 \
 && curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg \
    -o /usr/share/keyrings/tailscale-archive-keyring.gpg \
 && curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list \
    -o /etc/apt/sources.list.d/tailscale.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends tailscale \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/tailscale

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT []
CMD ["/run.sh"]
