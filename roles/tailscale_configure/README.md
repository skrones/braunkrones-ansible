# tailscale_configure

Installs and configures Tailscale with the `artis3n.tailscale.machine` collection role, then verifies that the node is connected.

Install the collection dependencies before running playbooks:

```bash
poetry run ansible-galaxy collection install -r requirements.yml
```

The bootstrap script runs this automatically.

## Example

```yaml
- role: tailscale_configure
  vars:
    tailscale_authkey: "{{ tailscale_authkey }}"
    tailscale_hostname: "{{ host_name }}"
    tailscale_accept_routes: true
```

Store `tailscale_authkey` in `secrets.yml`, Ansible Vault, or another protected variable source. The legacy wrapper variable `tailscale_auth_key` is also supported. The role fails unless `tailscale status --json` reports `BackendState` as `Running` after configuration.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `tailscale_state` | `present` | Install state passed to the collection role: `latest`, `present`, or `absent`. |
| `tailscale_release_stability` | `stable` | Tailscale package channel: `stable` or `unstable`. |
| `tailscale_authkey` | undefined | Auth key used by the collection role. If omitted, the collection skips `tailscale up`, and this wrapper will still fail unless the node is already connected. |
| `tailscale_auth_key` | undefined | Backward-compatible alias for `tailscale_authkey`. |
| `tailscale_hostname` | `{{ host_name | default(inventory_hostname) }}` | Hostname passed to `tailscale up`. |
| `tailscale_accept_routes` | `false` | Whether to accept subnet routes. |
| `tailscale_advertise_exit_node` | `false` | Whether to advertise this host as an exit node. |
| `tailscale_advertise_routes` | `[]` | Subnet routes to advertise. |
| `tailscale_tags` | `[]` | Tags to advertise during auth, without the `tag:` prefix. |
| `tailscale_ssh` | `false` | Whether to enable Tailscale SSH. |
| `tailscale_extra_args` | `[]` | Additional arguments appended to `tailscale up`. |
| `tailscale_up_timeout` | `120` | Timeout for `tailscale up`, in seconds. |
| `tailscale_oauth_ephemeral` | `true` | Whether OAuth-authenticated nodes are ephemeral. |
| `tailscale_oauth_preauthorized` | `false` | Whether OAuth-authenticated nodes are preauthorized. |
| `tailscale_verbose` | `false` | Enable verbose output from the collection role. |
| `tailscale_insecurely_log_authkey` | `false` | Allow the collection role to log the raw auth key while debugging failures. |
| `tailscale_auth_key_in_state` | `true` | Store a hashed auth key in Ansible state so auth key changes rerun `tailscale up`. |
| `tailscale_manage_binaries_skip` | `false` | Skip package install/removal and only manage Tailscale configuration. |