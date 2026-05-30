# sshd_configure

Hardens OpenSSH server settings with a drop-in config file instead of overwriting `/etc/ssh/sshd_config`.

The role refuses to continue unless the default SSHD config already includes `/etc/ssh/sshd_config.d/*.conf`. It writes the hardening file, validates SSHD configuration, and reloads `sshd` when the drop-in changes.

## Playbook Usage

```yaml
- hosts: all
  become: true
  roles:
    - role: sshd_install
    - role: sshd_configure
```

Run this after `sshd_install` and after you have working public key access. The defaults disable password login and root login.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `sshd_hardening_drop_in_path` | `/etc/ssh/sshd_config.d/90-hardening.conf` | Drop-in file managed by this role. |
| `sshd_hardening_options` | see defaults | Mapping of SSHD directives and values written to the drop-in. |

## Default Hardening

```yaml
sshd_hardening_options:
  PermitRootLogin: "no"
  PasswordAuthentication: "no"
  KbdInteractiveAuthentication: "no"
  PubkeyAuthentication: "yes"
  PermitEmptyPasswords: "no"
  X11Forwarding: "no"
  AllowAgentForwarding: "no"
  MaxAuthTries: "3"
  LoginGraceTime: "30"
  ClientAliveInterval: "300"
  ClientAliveCountMax: "2"
```

Override `sshd_hardening_options` in the playbook if a host needs a different hardening profile.