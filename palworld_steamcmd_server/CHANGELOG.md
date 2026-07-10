# Changelog

## 2.0.1

### Fixed
- Saving configuration failed with "Missing option 'backup_cron_expression'" for configs saved before 2.0.0 (new options are now optional)
- `crossplay_platforms` was written to PalWorldSettings.ini without the required parentheses, which could prevent clients from connecting

## 2.0.0

**Major internal rework — now built on [`thijsvanloef/palworld-server-docker`](https://github.com/thijsvanloef/palworld-server-docker) (rolling `v2` tag).**

Your world, players and settings carry over automatically — no migration needed. Server data stays at `/share/palworld/server/`.

### Added
- **Scheduled backups** — `backup_enabled` (default on) and `backup_cron_expression` (daily at midnight by default); backups stored under `/share/palworld/server/backups/`
- **Auto-update while running** — `auto_update_enabled` (default off)
- **Palworld REST API** — `rest_api_enabled` (default off), port 8212
- **aarch64 support** (upstream image is multi-arch)

### Changed
- SteamCMD install/updates, settings generation, RCON, Discord notifications and graceful shutdown are now handled by the upstream image; upstream fixes are picked up automatically on add-on updates
- `difficulty` default corrected from `Hard` (not a valid Palworld value) to `Difficult`; existing configs with `Hard` are mapped automatically
- `app_id` option is now ignored (the base image always installs Palworld)

### Removed
- `/share/palworld/config/` and `/share/palworld/steam_home/` are no longer used and can be deleted

## 1.5.4

- Last release of the from-scratch SteamCMD implementation (rollback tag: `v1.5.4-pre-thijsvanloef-base`)
