# Managed Node Setup

This script performs initial configuration of a Fedora/RHEL machine for Ansible management.

## Overview

The `managed-node-setup.sh` script automates the setup of a Fedora or RHEL machine as an Ansible-managed node. It installs OpenSSH server, configures SSH for key-based authentication, creates a dedicated Ansible user, installs SSH public keys from GitHub, and grants sudo privileges to the user.

## Prerequisites

- Fedora or RHEL operating system
- Root privileges (run as root or with sudo)
- Internet access for package installation and GitHub key fetching
- A GitHub account with SSH public keys uploaded

## Installation

Download the script and configuration file from the GitHub repository:

```bash
wget https://raw.githubusercontent.com/braunkrones/braunkrones-ansible/main/managed-node-setup/RHEL-Fedora/managed-node-setup.sh
wget https://raw.githubusercontent.com/braunkrones/braunkrones-ansible/main/managed-node-setup/RHEL-Fedora/managed-node-setup.yaml
chmod +x managed-node-setup.sh
```

## Usage

### Basic Usage

Create a password file for the new user:

```bash
echo "your_password_here" > /tmp/ansible_passwd.txt
chmod 600 /tmp/ansible_passwd.txt
```

Run the script with required arguments:

```bash
./managed-node-setup.sh -g <github_username> -p /tmp/ansible_passwd.txt
```

### Command-Line Options

- `-c <config_file>`: SSH config file name in `/etc/ssh/sshd_config.d/` (default: `managed-node-setup.conf`)
- `-u <username>`: Username for the new user (default: `ansible`)
- `-p <password_file>`: Path to file containing the password for the new user (required)
- `-g <github_username>`: GitHub username to fetch SSH public keys from (required)
- `-s <sudo_policy>`: Sudo policy for the new user (default: `ALL=(ALL) NOPASSWD: ALL`)
- `-h`: Show help message

### Configuration File

The script checks for `managed-node-setup.yaml` in the same directory. If present, it loads preset values from the file. Command-line options override YAML presets.

Example `managed-node-setup.yaml`:

```yaml
username: ansible
password_file: /tmp/ansible_passwd.txt
github_username: your_github_username
sudo_policy: ALL=(ALL) NOPASSWD: ALL
```

### Examples

Create a user named `ansible` with default settings:

```bash
./managed-node-setup.sh -g mygithubuser -p /tmp/ansible_passwd.txt
```

Create a user named `myuser` with custom config:

```bash
./managed-node-setup.sh -u myuser -c myconfig.conf -g mygithubuser -p /tmp/ansible_passwd.txt
```

Use YAML configuration:

```bash
# Edit managed-node-setup.yaml with your values
./managed-node-setup.sh
```

## What the Script Does

1. Installs OpenSSH server using `dnf` or `yum`
2. Starts and enables the SSH service
3. Creates a new SSH configuration file in `/etc/ssh/sshd_config.d/` to enable key-based authentication
4. Creates a new user with the specified username and password
5. Fetches SSH public keys from the specified GitHub user's account and installs them for both the executing user and the new user
6. Creates a sudo policy file in `/etc/sudoers.d/` granting the specified privileges to the new user
7. Restarts the SSH service to apply configuration changes

## Security Notes

- The password file should be secured with appropriate permissions and deleted after use
- SSH keys are fetched from GitHub and added to `authorized_keys` files
- The sudo policy grants passwordless sudo access; adjust as needed for your security requirements

## Troubleshooting

- Ensure you have root privileges
- Check that the password file exists and is readable
- Verify GitHub username has public SSH keys
- Review system logs for any errors during execution

## Contributing

Please report issues or submit pull requests to the [GitHub repository](https://github.com/braunkrones/braunkrones-ansible).