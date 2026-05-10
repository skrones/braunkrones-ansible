# Braunkrones Linux Machine First Use Setup

Automated Linux environment setup with SSH hardening and fail2ban protection.

## Overview

This repository contains a comprehensive bash script designed for initial setup of RHEL/Fedora-based Linux desktops. The script automates the following tasks:

- **System Updates**: Updates and upgrades all system packages
- **SSH Installation**: Installs and configures OpenSSH server
- **GitHub Key Import**: Automatically imports your public SSH keys from GitHub
- **SSHD Hardening**: Applies security best practices to SSH configuration
- **fail2ban Setup**: Installs and configures fail2ban for brute-force protection

## Features

### Security Hardening

The script implements industry-standard SSH security measures:

- **Disables password authentication** - Forces public key authentication only
- **Disables root login** - Prevents direct root SSH access
- **Disables X11 forwarding** - Reduces attack surface
- **Disables empty passwords** - Ensures strong authentication
- **Session timeout** - Auto-disconnects idle sessions after 5 minutes
- **Disables agent/TCP forwarding** - Prevents unauthorized tunneling

### fail2ban Protection

Monitors SSH authentication logs and temporarily bans IPs with failed login attempts:

- **Ban duration**: 1 hour
- **Threshold**: 5 failed attempts within 10 minutes
- **Monitoring**: Real-time tracking of authentication failures

### Non-Destructive Configuration

The script preserves your system's vendor SSH configuration:

- Creates a new include file (`/etc/ssh/sshd_config.d/99-hardening.conf`) instead of modifying the original
- Original `/etc/ssh/sshd_config` remains unchanged
- Easy to review, modify, or remove hardening settings

### Comprehensive Logging

All operations are logged to `/var/log/setup.log` with timestamps for troubleshooting and auditing.

## Requirements

- **Operating System**: RHEL/Fedora-based systems (CentOS, Fedora, Rocky Linux, AlmaLinux, etc.)
- **Privileges**: Must be run as root or with `sudo`
- **Network**: Internet connectivity to reach `github.com`
- **GitHub Account**: A public GitHub account with SSH keys configured

## Installation

Run Directly via Curl (Recommended for First-Time Setup)

Run the script directly from the repository without downloading:

```bash
# Replace 'your_github_username' with your actual GitHub username
sudo bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/braunkrones-ansible/main/Setup/setup.sh) your_github_username
```

**Note**: Adjust the GitHub repository URL to match your actual repository location.

## Usage

### Basic Syntax

```bash
sudo ./setup.sh <github_username>
```

### Arguments

- `<github_username>` (required): Your GitHub username whose public SSH keys will be imported

### Options

- `-h, --help`: Display help message and exit

### Examples

```bash
# Basic usage
sudo ./setup.sh myusername

# With help flag
sudo ./setup.sh -h

# Via curl
sudo bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/braunkrones-ansible/main/Setup/setup.sh) myusername
```

## What Gets Installed

The script installs the following packages on your system:

- `openssh-server` - SSH server daemon
- `openssh-clients` - SSH client utilities
- `curl` - For downloading SSH keys from GitHub
- `fail2ban` - Intrusion prevention framework
- `fail2ban-systemd` - fail2ban systemd integration

## Configuration Files

The script creates or modifies the following files:

| File | Purpose |
|------|---------|
| `/root/.ssh/authorized_keys` | Imported public SSH keys from GitHub |
| `/etc/ssh/sshd_config.d/99-hardening.conf` | SSH hardening configuration |
| `/etc/fail2ban/jail.d/sshd.local` | fail2ban SSHD jail rules |
| `/var/log/setup.log` | Setup script execution log |

## Verification

After running the script, verify the setup was successful:

### Check SSH Service Status

```bash
systemctl status sshd
```

Expected output should show `active (running)` and `enabled`.

### Verify SSH Keys Were Imported

```bash
wc -l ~/.ssh/authorized_keys
cat ~/.ssh/authorized_keys
```

### Verify SSHD Hardening

```bash
grep -E 'PasswordAuthentication|PermitRootLogin|ClientAliveInterval' /etc/ssh/sshd_config.d/99-hardening.conf
```

Expected output:
```
PasswordAuthentication no
PermitRootLogin no
ClientAliveInterval 300
```

### Check fail2ban Status

```bash
fail2ban-client status
fail2ban-client status sshd
```

Should show `sshd` jail is enabled and active.

### Test SSH Connection

From another machine with one of your SSH private keys:

```bash
ssh -i ~/.ssh/your_private_key root@<your_server_ip>
```

This should connect without requiring a password.

## Troubleshooting

### Script Fails Due to Missing GitHub Username

**Error**: `GitHub username argument is required`

**Solution**: Ensure you provide your GitHub username as an argument:
```bash
sudo ./setup.sh your_github_username
```

### No SSH Keys Found

**Error**: `No SSH keys found for GitHub user ...`

**Solution**: 
1. Verify the GitHub username is correct
2. Ensure you have public SSH keys on GitHub (https://github.com/username/keys)
3. Verify internet connectivity to github.com

### SSH Connection Fails

**Error**: Connection refused or timeout

**Solution**:
1. Verify SSHD is running: `systemctl status sshd`
2. Check SSH configuration: `sshd -t`
3. Review logs: `tail -20 /var/log/setup.log`
4. Check firewall: `sudo firewall-cmd --list-all` or `sudo iptables -L`

### fail2ban Not Protecting

**Error**: fail2ban service not active

**Solution**:
1. Check status: `systemctl status fail2ban`
2. Restart service: `sudo systemctl restart fail2ban`
3. Review logs: `sudo tail -20 /var/log/fail2ban.log`

## Logging

All script operations are logged to `/var/log/setup.log`. View the log:

```bash
tail -50 /var/log/setup.log
```

For real-time monitoring:

```bash
sudo tail -f /var/log/setup.log
```

## Security Considerations

- The script disables password authentication completely. Ensure you have SSH keys configured before running.
- Root login is disabled. Use a non-root account with sudo privileges for ongoing administration.
- Session timeouts are set to 5 minutes of inactivity. Adjust in `/etc/ssh/sshd_config.d/99-hardening.conf` if needed.
- fail2ban bans IPs for 1 hour after 5 failed attempts. Monitor ban status to avoid accidental lockouts.

## Reverting Changes

If you need to revert the SSH hardening:

```bash
# Remove the hardening configuration
sudo rm /etc/ssh/sshd_config.d/99-hardening.conf

# Reload SSHD
sudo systemctl reload sshd
```

## Support

For issues or questions, please check the following:

1. Review the script log: `cat /var/log/setup.log`
2. Verify system requirements are met
3. Ensure GitHub account and SSH keys are properly configured
4. Check system firewall and network connectivity

## License

MIT License - See repository for details

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
