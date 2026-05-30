# user_create

Creates a local user account and optionally installs a sudoers policy for that user.

The role also corrects ownership and permissions on the created user's home directory when home creation is enabled.

## Playbook Usage

```yaml
- hosts: all
  become: true
  vars_files:
    - secrets.yml
  roles:
    - role: user_create
      vars:
        user_name: ansible
        user_password: "{{ ansible_user_pass }}"
        system: true
        group: wheel
        sudo_policy: "ansible ALL=(ALL) NOPASSWD:ALL"
```

On Linux, `user_password` should be a hashed password suitable for the Ansible `user` module, not a plaintext password.

## Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `user_name` | yes | none | Name of the user to create. |
| `user_password` | yes | none | Password hash passed to `ansible.builtin.user`. |
| `system` | no | `false` | Whether to create a system account. |
| `group` | no | omitted | Supplementary group or groups for the user. |
| `create_home` | no | `true` | Whether to create and manage the user's home directory. |
| `user_home_mode` | no | `0750` | Mode applied to the home directory when `create_home` is true. |
| `sudo_policy` | no | undefined | Sudoers policy written to `/etc/sudoers.d/{{ user_name }}` when defined. |