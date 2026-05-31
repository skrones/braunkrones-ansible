# desktop_packages

Installs desktop RPM packages and DNF groups on Fedora/RHEL systems with `dnf5`.

Repository setup is intentionally outside this role. Run `desktop_repos` first so packages such as VS Code, Steam, and QDMR are available from their required repositories. Snap application installs and Flatpak application installs belong in separate roles; this role only installs and enables the `snapd` system package and service.

## Playbook Usage

```yaml
- hosts: desktops
  become: true
  roles:
    - role: desktop_repos
    - role: desktop_packages
      vars:
        desktop_user: sam
        desktop_packages_extra_packages:
          - vim-enhanced
        desktop_packages_excluded_packages:
          - steam
```

Set `desktop_user` when virtualization user membership is enabled. Group membership changes usually require a new login session before they are visible to the user.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `desktop_packages_default_packages` | `code`, `steam`, `zsh`, `snapd`, `qdmr`, `chezmoi`, `rclone` | RPM packages installed by default. Required repositories must already be configured. |
| `desktop_packages_extra_packages` | `[]` | Additional RPM packages to install. |
| `desktop_packages_excluded_packages` | `[]` | Packages removed from the combined default and extra package list. |
| `desktop_packages_default_groups` | `@virtualization` | DNF groups installed by default. |
| `desktop_packages_extra_groups` | `[]` | Additional DNF groups to install. |
| `desktop_packages_excluded_groups` | `[]` | Groups removed from the combined default and extra group list. |
| `desktop_packages_state` | `present` | Package and group state passed to `ansible.builtin.dnf5`. |
| `desktop_packages_update_cache` | `true` | Whether to refresh DNF metadata when installing packages. |
| `desktop_packages_manage_snapd` | `true` | Enable and start snapd system services after installing packages. |
| `desktop_packages_snapd_services` | `snapd.socket` | snapd units enabled and started by this role. |
| `desktop_packages_create_classic_snap_link` | `true` | Create `/snap` for classic snap compatibility. |
| `desktop_packages_classic_snap_link_path` | `/snap` | Path of the classic snap compatibility symlink. |
| `desktop_packages_classic_snap_target` | `/var/lib/snapd/snap` | Target of the classic snap compatibility symlink. |
| `desktop_packages_manage_virtualization` | `true` | Enable and start libvirt services after the virtualization group is installed. |
| `desktop_packages_manage_virtualization_user` | `true` | Add `desktop_user` to libvirt groups. |
| `desktop_user` | `""` | Local desktop account that should receive libvirt group membership. Required when virtualization user management is enabled. |
| `desktop_packages_libvirt_services` | `libvirtd` | libvirt units enabled and started by this role. |
| `desktop_packages_libvirt_groups` | `libvirt` | Groups assigned to `desktop_user` for virtualization management. |

## Notes

Use `desktop_packages_extra_packages` and `desktop_packages_excluded_packages` from playbooks or inventory instead of editing task files for machine-specific package choices. Keep repository definitions in `desktop_repos` so this role stays focused on DNF package and group installation.