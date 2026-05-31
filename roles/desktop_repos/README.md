# desktop_repos

Configures third-party DNF repositories required by the default package list in `desktop_packages`.

## Repository Mapping

| Package | Repository source |
| --- | --- |
| `code` | Microsoft VS Code yum repository |
| `steam` | RPM Fusion nonfree repository on Fedora |
| `zsh` | Fedora/RHEL base repositories |
| `snapd` | Fedora base repositories |
| `qdmr` | Fedora base repositories |
| `chezmoi` | Fedora base repositories |

## Playbook Usage

```yaml
- hosts: desktops
  become: true
  roles:
    - role: desktop_repos
    - role: desktop_packages
```

Run this role before `desktop_packages` so the package installer can resolve packages from Microsoft and RPM Fusion.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `desktop_repos_manage_vscode` | `true` | Configure the Microsoft VS Code repository used by the `code` package. |
| `desktop_repos_manage_rpmfusion` | `true` | Install RPM Fusion free and nonfree release repositories on Fedora. |
| `desktop_repos_state` | `present` | Repository state passed to repo management tasks. |
| `desktop_repos_update_cache` | `true` | Refresh DNF metadata while installing RPM Fusion release packages. |
| `desktop_repos_vscode_name` | `vscode` | Repo ID for the Microsoft VS Code repository. |
| `desktop_repos_vscode_description` | `Visual Studio Code` | Human-readable VS Code repository description. |
| `desktop_repos_vscode_baseurl` | `https://packages.microsoft.com/yumrepos/vscode` | VS Code repository base URL. |
| `desktop_repos_vscode_gpgkey` | `https://packages.microsoft.com/keys/microsoft.asc` | Microsoft package signing key URL. |
| `desktop_repos_vscode_gpgcheck` | `true` | Enable GPG checking for VS Code packages. |
| `desktop_repos_vscode_enabled` | `true` | Enable the VS Code repository. |
| `desktop_repos_rpmfusion_release_packages` | RPM Fusion free and nonfree Fedora release RPM URLs | Release packages that add RPM Fusion repositories. |
| `desktop_repos_rpmfusion_disable_gpg_check` | `true` | Disable GPG checking for RPM Fusion release RPM installation. The installed repositories still manage their package signing keys. |

## Notes

RPM Fusion repository installation is limited to Fedora because the default `desktop_packages` package set uses Fedora-oriented packages such as Steam. Override `desktop_packages_default_packages` or exclude `steam` when targeting RHEL-family hosts where that package is not available.