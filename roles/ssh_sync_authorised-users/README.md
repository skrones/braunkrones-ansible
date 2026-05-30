# ssh_sync_authorised-users

Downloads SSH public keys from the GitHub user keys API and writes matching keys to a local user's `authorized_keys` file.

The role selects GitHub keys by title prefix. For example, `github_key_title_prefix: "ansible@"` matches GitHub SSH keys whose titles begin with `ansible@`.

## Playbook Usage

```yaml
- hosts: all
  become: true
  vars_files:
    - secrets.yml
  roles:
    - role: ssh_sync_authorised-users
      vars:
        ssh_key_user: ansible
        github_key_title_prefix: "ansible@"
```

Store `github_token` in `secrets.yml`, Ansible Vault, or another protected variable source. The token must be able to read the authenticated user's SSH keys.

This role overwrites `authorized_keys` for `ssh_key_user` with the matching GitHub keys.

## Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `ssh_key_user` | yes | none | Local user whose `authorized_keys` file should be managed. |
| `github_token` | yes | none | GitHub token used for the GitHub keys API request. |
| `github_key_title_prefix` | no | `{{ ssh_key_user }}@` | Only GitHub keys with titles matching this prefix are authorized. |
| `github_keys_api_url` | no | `https://api.github.com/user/keys` | GitHub API endpoint to query. |