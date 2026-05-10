#!/bin/bash
#
# managed-node-setup.sh
#
# This script performs initial configuration of a Fedora/RHEL machine for Ansible management.
# It installs OpenSSH server, configures SSH for key-based authentication, creates an Ansible user,
# installs SSH public keys from GitHub, and sets up sudo privileges.
#
# Usage: ./managed-node-setup.sh -g <github_username> -p <password_file> [options]
#
# Options:
#   -c <config_file>    SSH config file name (default: managed-node-setup.conf)
#   -u <username>       New user username (default: ansible)
#   -p <password_file>  File containing the password for the new user (required)
#   -g <github_username> GitHub username to fetch SSH keys from (required)
#   -h                  Show this help message
#
# The script also checks for 'managed-node-setup.yaml' in the same directory for preset options.

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly YAML_FILE="${SCRIPT_DIR}/managed-node-setup.yaml"
readonly SSH_CONFIG_DIR="/etc/ssh/sshd_config.d"
readonly SUDOERS_DIR="/etc/sudoers.d"

# Default values
CONFIG_FILE="managed-node-setup.conf"
USERNAME="ansible"
PASSWORD_FILE=""
GITHUB_USERNAME=""
SUDO_POLICY="ALL=(ALL) NOPASSWD: ALL"

# Functions

# usage: Print usage information
usage() {
  cat << EOF
Usage: $0 -g <github_username> -p <password_file> [options]

This script configures a Fedora/RHEL machine for Ansible management by:
- Installing and enabling OpenSSH server
- Creating a new SSH config file for key-based authentication
- Creating a new user with specified password
- Installing SSH public keys from GitHub for both the executing user and the new user
- Granting sudo privileges to the new user without password

Options:
  -c <config_file>     SSH config file name in ${SSH_CONFIG_DIR}/ (default: ${CONFIG_FILE})
  -u <username>        Username for the new user (default: ${USERNAME})
  -p <password_file>   Path to file containing the password for the new user (required)
  -g <github_username> GitHub username to fetch SSH public keys from (required)
  -s <sudo_policy>     Sudo policy for the new user (default: ${SUDO_POLICY})
  -h                   Show this help message

Configuration:
  The script checks for '${YAML_FILE}' in the script directory.
  If present, it loads preset values in YAML format (key: value pairs).
  Command-line options override YAML presets.

Examples:
  $0 -g mygithubuser -p /tmp/passwd.txt
  $0 -u myuser -c myconfig.conf -s "ALL=(ALL) NOPASSWD: /bin/ls" -g mygithubuser -p /tmp/passwd.txt

EOF
}

# load_yaml: Load configuration from YAML file if it exists
load_yaml() {
  if [[ -f "${YAML_FILE}" ]]; then
    echo "Loading configuration from ${YAML_FILE}..."
    while IFS=':' read -r key value; do
      # Trim whitespace
      key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      case "$key" in
        config_file) CONFIG_FILE="${value:-$CONFIG_FILE}" ;;
        username) USERNAME="${value:-$USERNAME}" ;;
        password_file) PASSWORD_FILE="${value:-$PASSWORD_FILE}" ;;
        github_username) GITHUB_USERNAME="${value:-$GITHUB_USERNAME}" ;;
        sudo_policy) SUDO_POLICY="${value:-$SUDO_POLICY}" ;;
      esac
    done < "${YAML_FILE}"
  fi
}

# parse_args: Parse command-line arguments
parse_args() {
  while getopts "c:u:p:g:s:h" opt; do
    case "$opt" in
      c) CONFIG_FILE="$OPTARG" ;;
      u) USERNAME="$OPTARG" ;;
      p) PASSWORD_FILE="$OPTARG" ;;
      g) GITHUB_USERNAME="$OPTARG" ;;
      s) SUDO_POLICY="$OPTARG" ;;
      h) usage; exit 0 ;;
      *) usage; exit 1 ;;
    esac
  done
}

# validate_inputs: Check required inputs
validate_inputs() {
  if [[ -z "$PASSWORD_FILE" ]]; then
    echo "Error: Password file is required. Use -p <password_file>" >&2
    usage
    exit 1
  fi
  if [[ ! -f "$PASSWORD_FILE" ]]; then
    echo "Error: Password file '$PASSWORD_FILE' does not exist." >&2
    exit 1
  fi
  if [[ -z "$GITHUB_USERNAME" ]]; then
    echo "Error: GitHub username is required. Use -g <github_username>" >&2
    usage
    exit 1
  fi
}

# install_openssh: Install OpenSSH server
install_openssh() {
  echo "Installing OpenSSH server..."
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y openssh-server
  elif command -v yum >/dev/null 2>&1; then
    yum install -y openssh-server
  else
    echo "Error: Neither dnf nor yum found." >&2
    exit 1
  fi
}

# start_enable_sshd: Start and enable SSH service
start_enable_sshd() {
  echo "Starting and enabling SSH service..."
  systemctl start sshd
  systemctl enable sshd
}

# restart_sshd: Restart SSH service to apply config changes
restart_sshd() {
  echo "Restarting SSH service to apply configuration changes..."
  systemctl restart sshd
}

# create_sshd_config: Create SSH config file
create_sshd_config() {
  local config_path="${SSH_CONFIG_DIR}/${CONFIG_FILE}"
  echo "Creating SSH config file: ${config_path}"
  cat > "$config_path" << EOF
# SSH config for managed node setup
# Enables key-based authentication
PubkeyAuthentication yes
EOF
  chmod 644 "$config_path"
}

# create_user: Create new user and set password
create_user() {
  echo "Creating user: ${USERNAME}"
  useradd -m "$USERNAME"
  local password
  password=$(<"$PASSWORD_FILE")
  echo "${USERNAME}:${password}" | chpasswd
}

# install_ssh_keys: Install SSH keys from GitHub
install_ssh_keys() {
  local keys_url="https://github.com/${GITHUB_USERNAME}.keys"
  echo "Fetching SSH keys from ${keys_url}..."

  local keys
  keys=$(curl -s "$keys_url")
  if [[ -z "$keys" ]]; then
    echo "Warning: No SSH keys found for GitHub user '${GITHUB_USERNAME}'."
    return
  fi

  # Install for executing user
  local exec_user_home
  exec_user_home=$(getent passwd "$USER" | cut -d: -f6)
  local exec_auth_keys="${exec_user_home}/.ssh/authorized_keys"
  mkdir -p "${exec_user_home}/.ssh"
  echo "$keys" >> "$exec_auth_keys"
  chmod 600 "$exec_auth_keys"
  chown "$USER" "$exec_auth_keys"

  # Install for new user
  local user_home="/home/${USERNAME}"
  local user_auth_keys="${user_home}/.ssh/authorized_keys"
  mkdir -p "${user_home}/.ssh"
  echo "$keys" >> "$user_auth_keys"
  chmod 600 "$user_auth_keys"
  chown "$USERNAME:$USERNAME" "$user_auth_keys"
}

# create_sudo_policy: Create sudo policy for the user
create_sudo_policy() {
  local sudo_file="${SUDOERS_DIR}/${USERNAME}"
  echo "Creating sudo policy: ${sudo_file}"
  cat > "$sudo_file" << EOF
# Sudo policy for ${USERNAME}
${USERNAME} ${SUDO_POLICY}
EOF
  chmod 440 "$sudo_file"
}

# main: Main function
main() {
  load_yaml
  parse_args "$@"
  validate_inputs

  echo "Starting managed node setup..."
  install_openssh
  start_enable_sshd
  create_sshd_config
  create_user
  install_ssh_keys
  create_sudo_policy
  restart_sshd
  echo "Setup complete."
}

# Run main
main "$@"