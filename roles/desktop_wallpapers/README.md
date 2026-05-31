# desktop_wallpapers

Syncs a Google Photos album with `rclone` and configures user-level systemd timers to refresh local wallpaper files and rotate wallpapers with HydraPaper.

Run `desktop_packages` first so `rclone` is installed, and run `desktop_flatpacks` first so HydraPaper is installed from Flathub. The role can install a prebuilt `rclone.conf` for the desktop user so no browser authentication is required during Ansible runs.

## Playbook Usage

```yaml
- hosts: desktops
  become: true
  roles:
    - role: desktop_wallpapers
      vars:
        desktop_user: sam
        desktop_wallpapers_google_photos_album: Wallpapers
```

The desktop setup playbook runs this role by default and prompts for the desktop user and Google Photos album name:

```bash
poetry run ansible-playbook playbooks/desktop-setup.yml
```

Store the rclone config in `secrets.yml` with Ansible Vault:

```yaml
vault_desktop_wallpapers_rclone_config_content: |
  [gphotos]
  type = google photos
  token = {"access_token":"...","token_type":"Bearer","refresh_token":"...","expiry":"..."}
```

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `desktop_wallpapers_enabled` | `true` | Documents that the desktop setup playbook runs this role by default. |
| `desktop_user` | undefined | Local desktop account that owns the wallpaper files and user systemd units. |
| `desktop_wallpapers_directory` | `~/Pictures/Wallpapers` | Local wallpaper sync destination. |
| `desktop_wallpapers_fetch_enabled` | `true` | Install and enable the rclone sync timer. |
| `desktop_wallpapers_rclone_remote` | `gphotos` | Name of the configured rclone Google Photos remote. |
| `desktop_wallpapers_google_photos_album` | `""` | Google Photos album name to sync from `remote:album/name`. Required when fetch is enabled. |
| `desktop_wallpapers_rclone_extra_args` | `[]` | Extra arguments appended to `rclone sync`. |
| `desktop_wallpapers_manage_rclone_config` | `true` | Install `rclone.conf` for the desktop user from a supplied variable. |
| `desktop_wallpapers_rclone_config_content` | `""` | Full `rclone.conf` content. The desktop playbook maps this from `vault_desktop_wallpapers_rclone_config_content`. |
| `desktop_wallpapers_rclone_config_path` | `~/.config/rclone/rclone.conf` | Destination config file used by the sync service. |
| `desktop_wallpapers_rclone_config_directory_mode` | `0700` | Mode for the rclone config directory. |
| `desktop_wallpapers_rclone_config_file_mode` | `0600` | Mode for the rclone config file. |
| `desktop_wallpapers_manage_user_linger` | `true` | Enable lingering so the user's systemd manager can run timers. |
| `desktop_wallpapers_start_user_manager` | `true` | Start `user@UID.service` before enabling user timers. |
| `desktop_wallpapers_start_timers` | `true` | Start timers immediately after enabling them. |
| `desktop_wallpapers_config_directory_mode` | `0700` | Mode for the managed user config directories. |
| `desktop_wallpapers_wallpaper_directory_mode` | `0750` | Mode for the wallpaper directory and its immediate parent. |
| `desktop_wallpapers_unit_file_mode` | `0644` | Mode for managed user systemd unit files. |
| `desktop_wallpapers_sync_on_boot` | `5m` | Delay before the first wallpaper sync after boot. |
| `desktop_wallpapers_sync_on_unit_active` | `6h` | Interval between rclone sync runs. |
| `desktop_wallpapers_hydrapaper_on_boot` | `2m` | Delay before the first HydraPaper rotation after boot. |
| `desktop_wallpapers_hydrapaper_on_unit_active` | `1m` | Interval between HydraPaper rotations. |

## Notes

Google Photos requires OAuth consent to create the initial token. To keep managed hosts noninteractive, generate the `rclone.conf` once on an admin workstation, store it in Ansible Vault, and let this role deploy it to the desktop user. The source path is built as `{{ desktop_wallpapers_rclone_remote }}:album/{{ desktop_wallpapers_google_photos_album }}`.