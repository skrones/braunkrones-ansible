# ssh_create_keypair

Creates an SSH key pair for an existing local user.

The role looks up the target user's home directory, ensures the user's `.ssh` directory exists, creates an OpenSSH key pair, fixes public key ownership, and registers the public key content as `ssh_public_key` when the public key exists.

## Playbook Usage

```yaml
- hosts: all
  become: true
  roles:
    - role: ssh_create_keypair
      vars:
        ssh_key_user: ansible
        type: ed25519
        comment: "ansible@{{ inventory_hostname }}"
        regenerate: never
```

Run this role after the user account has been created.

## Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `ssh_key_user` | yes | none | Local user that should own the key pair. |
| `type` | no | `ed25519` | SSH key type passed to `community.crypto.openssh_keypair`. |
| `comment` | no | `{{ ssh_key_user }}@{{ host_name }}` | Public key comment. |
| `regenerate` | no | `never` | Regeneration policy passed to `community.crypto.openssh_keypair`. |

## Dependencies

Requires the `community.crypto` collection.