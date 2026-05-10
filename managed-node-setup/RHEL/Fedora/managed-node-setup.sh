#!/bin/bash

################################################################################
# Linux Desktop SSH Hardening Setup Script
# Purpose: Initialize SSH, import GitHub keys, harden SSHD, install fail2ban
# Target: RHEL/Fedora-based systems
# Usage: sudo ./setup.sh <github_username>
################################################################################

set -euo pipefail

################################################################################
# Configuration
################################################################################

readonly LOG_FILE="/var/log/setup.log"
readonly SSHD_HARDENING_CONFIG="/etc/ssh/sshd_config.d/braunkrones.conf"
readonly FAIL2BAN_JAIL_CONFIG="/etc/fail2ban/jail.d/sshd.local"
readonly SSH_KEYS_URL="https://github.com"
readonly TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

################################################################################
# Functions
################################################################################

# Display usage information and exit.
usage() {
    local exit_code="${1:-0}"
    cat <<EOF
Usage: ${0##*/} <github_username>

Purpose:
  Initialize SSH on a new Linux desktop, import SSH keys from GitHub,
  harden SSHD configuration, and install fail2ban protection.

Arguments:
  github_username    GitHub username to import public SSH keys from

Options:
  -h, --help         Display this help message and exit

Requirements:
  - Must be run as root or with sudo privileges
  - System must be RHEL/Fedora-based (uses dnf package manager)
  - Internet connectivity to reach github.com

Example:
  sudo ${0##*/} myusername

EOF
    exit "${exit_code}"
}

# Log message with timestamp to logfile and stdout.
#
# Globals:
#   LOG_FILE
#   TIMESTAMP
# Arguments:
#   level: Log level (INFO, ERROR, WARN)
#   message: Message to log
log() {
    local level="$1"
    shift
    local message="$@"
    echo "[${TIMESTAMP}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Error handler - cleanup and exit on unexpected errors.
#
# Globals:
#   LINENO
# Arguments:
#   line_number: Line number where error occurred
#   message: Error message
error_exit() {
    local line_number="$1"
    local message="${2:-Unknown error}"
    log "ERROR" "Script failed at line ${line_number}: ${message}"
    exit 1
}

# Trap errors and call error handler.
trap 'error_exit ${LINENO} "Unexpected error"' ERR

# Check if running as root and exit if not.
#
# Returns:
#   0 if running as root, exits with 1 otherwise
check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        log "ERROR" "This script must be run as root or with sudo"
        exit 1
    fi
    log "INFO" "Running as root - proceeding with setup"
}

# Validate GitHub username argument.
#
# Arguments:
#   username: GitHub username to validate
# Returns:
#   0 on success, exits with 1 on invalid input
validate_github_username() {
    # Handle help flags
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage 1
    fi
    
    GITHUB_USERNAME="$1"
    
    # Validate username format
    if [[ ! "${GITHUB_USERNAME}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log "ERROR" "Invalid GitHub username format: ${GITHUB_USERNAME}"
        echo "Error: GitHub username must contain only alphanumeric characters, hyphens, or underscores" >&2
        usage 1
    fi
    log "INFO" "GitHub username validated: ${GITHUB_USERNAME}"
}

# Update and upgrade system packages.
#
# Uses dnf to update and upgrade all system packages.
#
# Returns:
#   0 on success, exits with 1 on failure
update_system() {
    log "INFO" "Updating and upgrading system packages..."
    if dnf update -y && dnf upgrade -y; then
        log "INFO" "System update and upgrade completed successfully"
    else
        error_exit ${LINENO} "Failed to update/upgrade system"
    fi
}

# Install prerequisite packages.
#
# Installs openssh-server, openssh-clients, curl, fail2ban, and fail2ban-systemd.
#
# Returns:
#   0 on success, exits with 1 on failure
install_prerequisites() {
    log "INFO" "Installing prerequisite packages..."
    local packages="openssh-server openssh-clients curl fail2ban fail2ban-systemd"
    
    if dnf install -y ${packages}; then
        log "INFO" "Prerequisites installed successfully"
    else
        error_exit ${LINENO} "Failed to install prerequisite packages"
    fi
}

# Setup SSH directory and import public keys from GitHub.
#
# Creates ~/.ssh directory with proper permissions (700) and imports
# public SSH keys from the specified GitHub user's public keys endpoint.
#
# Globals:
#   GITHUB_USERNAME
#   SSH_KEYS_URL
# Returns:
#   0 on success, exits with 1 on failure
setup_ssh_keys() {
    log "INFO" "Setting up SSH directory and importing GitHub public keys..."
    
    local ssh_dir="/root/.ssh"
    local authorized_keys="${ssh_dir}/authorized_keys"
    
    # Create .ssh directory with correct permissions
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        log "INFO" "Created SSH directory: ${ssh_dir}"
    else
        chmod 700 "$ssh_dir"
        log "INFO" "SSH directory exists, permissions set to 700"
    fi
    
    # Fetch public keys from GitHub
    log "INFO" "Fetching public keys from GitHub user: ${GITHUB_USERNAME}"
    local github_keys_url="${SSH_KEYS_URL}/${GITHUB_USERNAME}.keys"
    
    if ! curl -sf "$github_keys_url" -o "${authorized_keys}.tmp"; then
        error_exit ${LINENO} "Failed to fetch SSH keys from GitHub for user ${GITHUB_USERNAME}"
    fi
    
    # Validate that keys were actually retrieved
    if [[ ! -s "${authorized_keys}.tmp" ]]; then
        rm -f "${authorized_keys}.tmp"
        error_exit ${LINENO} "No SSH keys found for GitHub user ${GITHUB_USERNAME}"
    fi
    
    # Move temporary file to authorized_keys
    mv "${authorized_keys}.tmp" "$authorized_keys"
    chmod 600 "$authorized_keys"
    
    log "INFO" "SSH public keys imported successfully"
    log "INFO" "Imported $(wc -l < "$authorized_keys") key(s)"
}

# Create SSHD hardening configuration file.
#
# Creates /etc/ssh/sshd_config.d/SSHD_HARDENING_CONFIG with security best
# practices including disabling password auth, root login, and enabling
# session timeouts. Validates configuration syntax before returning.
#
# Globals:
#   SSHD_HARDENING_CONFIG
# Returns:
#   0 on success, exits with 1 on failure
harden_sshd() {
    log "INFO" "Creating SSHD hardening configuration..."
    
    # Create sshd_config.d directory if it doesn't exist
    mkdir -p /etc/ssh/sshd_config.d
    
    # Create hardening configuration file
    cat > "$SSHD_HARDENING_CONFIG" << 'EOF'
# SSH Security Hardening Configuration
# This file is included by /etc/ssh/sshd_config and should not be modified manually

# Disable password authentication - require public key only
PasswordAuthentication no

# Disable root login
PermitRootLogin no

# Require public key authentication
PubkeyAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Disable X11 forwarding
X11Forwarding no

# Set client idle timeout to 5 minutes
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable other risky features
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
EOF

    log "INFO" "SSHD hardening configuration created: ${SSHD_HARDENING_CONFIG}"
    
    # Validate SSH configuration syntax
    if sshd -t 2>&1; then
        log "INFO" "SSH configuration syntax validation passed"
    else
        error_exit ${LINENO} "SSH configuration syntax validation failed"
    fi
}

# Start and enable SSHD service.
#
# Starts the sshd service immediately and enables it for automatic startup
# on system boot. Verifies the service is running before returning.
#
# Returns:
#   0 on success, exits with 1 on failure
enable_sshd() {
    log "INFO" "Starting and enabling SSHD service..."
    
    if systemctl start sshd; then
        log "INFO" "SSHD service started"
    else
        error_exit ${LINENO} "Failed to start SSHD service"
    fi
    
    if systemctl enable sshd; then
        log "INFO" "SSHD enabled for auto-start on boot"
    else
        error_exit ${LINENO} "Failed to enable SSHD on boot"
    fi
    
    # Verify service status
    if systemctl is-active --quiet sshd; then
        log "INFO" "SSHD service verification successful"
    else
        error_exit ${LINENO} "SSHD service is not active"
    fi
}

# Configure and enable fail2ban for SSHD protection.
#
# Creates fail2ban jail configuration for SSHD with sensible defaults:
# - maxretry: 5 failed attempts
# - findtime: 600 seconds (10 minutes)
# - bantime: 3600 seconds (1 hour)
#
# Starts the fail2ban service and enables it for automatic startup on boot.
# Verifies the service is running before returning.
#
# Globals:
#   FAIL2BAN_JAIL_CONFIG
# Returns:
#   0 on success, exits with 1 on failure
configure_fail2ban() {
    log "INFO" "Configuring fail2ban for SSHD protection..."
    
    # Create fail2ban jail directory if it doesn't exist
    mkdir -p /etc/fail2ban/jail.d
    
    # Create fail2ban SSHD jail configuration
    cat > "$FAIL2BAN_JAIL_CONFIG" << 'EOF'
# fail2ban jail configuration for SSHD
# Monitor SSH authentication failures and temporarily ban offending IPs

[sshd]
enabled = true
port = ssh
logpath = %(syslog_authpriv)s
backend = %(syslog_backend)s
maxretry = 5
findtime = 600
bantime = 3600
EOF

    log "INFO" "fail2ban SSHD jail configuration created: ${FAIL2BAN_JAIL_CONFIG}"
    
    # Start and enable fail2ban service
    if systemctl start fail2ban; then
        log "INFO" "fail2ban service started"
    else
        error_exit ${LINENO} "Failed to start fail2ban service"
    fi
    
    if systemctl enable fail2ban; then
        log "INFO" "fail2ban enabled for auto-start on boot"
    else
        error_exit ${LINENO} "Failed to enable fail2ban on boot"
    fi
    
    # Verify fail2ban status
    if systemctl is-active --quiet fail2ban; then
        log "INFO" "fail2ban service verification successful"
    else
        error_exit ${LINENO} "fail2ban service is not active"
    fi
}

# Display completion summary and next steps.
#
# Logs a summary of all completed setup tasks and provides instructions
# for testing and verifying the configuration.
#
# Globals:
#   LOG_FILE
#   SSHD_HARDENING_CONFIG
#   GITHUB_USERNAME
completion_summary() {
    log "INFO" "=========================================="
    log "INFO" "SSH Setup and Hardening Completed!"
    log "INFO" "=========================================="
    log "INFO" "Summary of changes:"
    log "INFO" "  - System updated and upgraded"
    log "INFO" "  - OpenSSH server installed and enabled"
    log "INFO" "  - SSH public keys imported from GitHub (${GITHUB_USERNAME})"
    log "INFO" "  - SSHD hardened via ${SSHD_HARDENING_CONFIG}"
    log "INFO" "  - fail2ban installed and monitoring SSHD"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "  1. Test SSH connection from another machine:"
    log "INFO" "     ssh -i <your_private_key> root@<host>"
    log "INFO" "  2. Verify hardening is active:"
    log "INFO" "     grep -E 'PasswordAuthentication|PermitRootLogin' /etc/ssh/sshd_config.d/99-hardening.conf"
    log "INFO" "  3. Check fail2ban status:"
    log "INFO" "     fail2ban-client status sshd"
    log "INFO" ""
    log "INFO" "Log file: ${LOG_FILE}"
    log "INFO" "=========================================="
}

################################################################################
# Main Execution
################################################################################

# Main entry point for the setup script.
#
# Orchestrates the complete SSH setup and hardening workflow:
# 1. Validates root privileges and arguments
# 2. Updates system packages
# 3. Installs required software
# 4. Imports SSH keys from GitHub
# 5. Hardens SSHD configuration
# 6. Enables and verifies SSHD service
# 7. Configures fail2ban protection
#
# Arguments:
#   $@: Command-line arguments passed to the script
# Returns:
#   0 on successful completion, 1 on any failure
main() {
    check_root
    validate_github_username "$@"
    
    log "INFO" "Starting SSH setup and hardening script"
    log "INFO" "System: $(uname -n)"
    log "INFO" "Kernel: $(uname -r)"
    
    update_system
    install_prerequisites
    setup_ssh_keys
    harden_sshd
    enable_sshd
    configure_fail2ban
    completion_summary
    
    log "INFO" "Setup script completed successfully"
    exit 0
}

main "$@"
