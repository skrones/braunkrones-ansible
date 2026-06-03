# upload_settings

Exports desktop settings into a user's chezmoi source directory and refreshes
tracked dotfiles with `chezmoi re-add`.

## Playbook Usage

```yaml
- hosts: desktops
  become: true
  vars:
    desktop_user: sam
  roles:
    - role: upload_settings
```

Run the role after `desktop_packages` when the playbook is also responsible for
installing `chezmoi`. The target user must already have initialized chezmoi.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `upload_settings_user` | `{{ desktop_user | default('') }}` | Local account whose chezmoi source should be updated. |
| `upload_settings_gnome_extensions_file` | `gnome-extensions.txt` | File used for the enabled GNOME extension list. |
| `upload_settings_dump_script_path` | `dump-gnome-settings.sh` | Path to the dump script, relative to the chezmoi source directory. |
| `upload_settings_git_commit_message` | `Update desktop settings` | Commit message used when exported settings change. |

## Notes

The role commits changed settings when exports modify the chezmoi source, then
pushes the chezmoi source repository. Hosts that push over SSH need the target
user's git identity and repository credentials configured before the role runs.