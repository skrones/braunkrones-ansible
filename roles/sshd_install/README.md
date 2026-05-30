# sshd_install

Installs OpenSSH Server and ensures the `sshd` service is enabled and running.

This role is Fedora/RHEL-oriented and uses `ansible.builtin.dnf5`.

## Playbook Usage

```yaml
- hosts: all
  become: true
  roles:
    - role: sshd_install
```

Run this before roles that depend on the SSHD service, such as `sshd_configure`.

## Behavior

- Installs the `openssh-server` package.
- Starts `sshd`.
- Enables `sshd` at boot.