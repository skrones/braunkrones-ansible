# desktop_wallpapers

Creates a desktop wallpaper directory and configures a user-level systemd timer to rotate wallpapers with HydraPaper.

Run `desktop_flatpacks` first so HydraPaper is installed from Flathub. This role does not download wallpapers; manually place images in the managed wallpaper directory.

## Playbook Usage

```yaml
- hosts: desktops
  become: true
  roles:
    - role: desktop_wallpapers
      vars:
        desktop_user: sam
```

The desktop setup playbook runs this role by default and prompts for the desktop user:

```bash
poetry run ansible-playbook playbooks/desktop-setup.yml
```

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `desktop_wallpapers_enabled` | `true` | Documents that the desktop setup playbook runs this role by default. |
| `desktop_user` | undefined | Local desktop account that owns the wallpaper files and user systemd units. |
| `desktop_wallpapers_directory` | `~/Pictures/Wallpapers` | Local wallpaper directory to create for manual image placement. |
| `desktop_wallpapers_manage_user_linger` | `true` | Enable lingering so the user's systemd manager can run timers. |
| `desktop_wallpapers_start_user_manager` | `true` | Start `user@UID.service` before enabling user timers. |
| `desktop_wallpapers_start_timers` | `true` | Start timers immediately after enabling them. |
| `desktop_wallpapers_config_directory_mode` | `0700` | Mode for the managed user config directories. |
| `desktop_wallpapers_wallpaper_directory_mode` | `0750` | Mode for the wallpaper directory and its immediate parent. |
| `desktop_wallpapers_unit_file_mode` | `0644` | Mode for managed user systemd unit files. |
| `desktop_wallpapers_hydrapaper_on_boot` | `2m` | Delay before the first HydraPaper rotation after boot. |
| `desktop_wallpapers_hydrapaper_on_unit_active` | `1m` | Interval between HydraPaper rotations. |

## Notes

The role creates `desktop_wallpapers_directory` with ownership assigned to `desktop_user`. Add or remove wallpaper images manually in that directory; the HydraPaper timer rotates from the images HydraPaper can see.