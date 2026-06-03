# download_settings

Updates a user's desktop settings from their chezmoi source directory, reconciles
GNOME extensions with the exported extension list, then applies chezmoi-managed
files.

## Playbook Usage

```yaml
- hosts: desktops
  become: true
  vars:
    desktop_user: sam
  roles:
    - role: download_settings
```

Run the role after `desktop_packages` when the playbook is also responsible for
installing `chezmoi`. The target user must already have initialized chezmoi.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `download_settings_user` | `{{ desktop_user | default('') }}` | Local account whose chezmoi settings should be applied. |
| `download_settings_gnome_extensions_file` | `gnome-extensions.txt` | File used for the GNOME extension list, relative to the chezmoi source directory. |

## Notes

The role runs `git pull`, reconciles installed GNOME extensions to match the
extension list, enables each listed extension, and runs `chezmoi apply --force`
every time it is called. Missing GNOME extension bundles are downloaded from
extensions.gnome.org and installed with `gnome-extensions install --force`.
Extra user-installed extensions are removed, while system extensions are left
installed and omitted from the enabled extension list. If the target user has
active logind sessions, the role notifies a handler that schedules a delayed
`loginctl terminate-user` at the end of the play so GNOME Shell starts fresh on
the next login.