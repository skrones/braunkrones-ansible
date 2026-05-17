#!/bin/bash
#
# Bootstrap script automating the initial configuration of a Fedora/RHEL machine for ansible management & control.

set -euo pipefail

# Ensure the script isnnot run as root. Running as root breaks pipx and poetry install.
check_not_root() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "Do not run this script with sudo. Run it as your normal user; it will ask for sudo when needed." >&2
        exit 1
    fi
}

# Ensure the user has sudo access and keep the sudo session alive for the duration of the script.
init_sudo() {
    echo "Checking sudo access..." >&2
    sudo -v

    # Keep sudo timestamp fresh while the script runs.
    while true; do
        sudo -n true
        sleep 60
    done 2>/dev/null &

    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

# Check for the presence of a supported package manager and set the PACKAGE_MANAGER variable accordingly.
check_for_package_manager() {
    if command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
    else
        echo "No supported package manager found." >&2
        exit 1
    fi
}

# List of packages required for the bootstrap process.
# The script will check if each package is already installed before attempting installation.
packages=(
    "git"
    "python"
    "pipx"
)

# Install required packages if they are not already installed.
install_packages() {
    for package in "${packages[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            echo "Installing $package..." >&2
            sudo "$PACKAGE_MANAGER" install -y "$package"
        else
            echo "$package is already installed." >&2
        fi
    done
}

# Install poetry using pipx if it's not already installed.
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v poetry >/dev/null 2>&1; then
        echo "Installing poetry..." >&2
        pipx install poetry
    else
        echo "poetry is already installed." >&2
    fi

    if ! command -v poetry >/dev/null 2>&1; then
        echo "Poetry was installed, but is still not available on PATH." >&2
        echo "Expected it at: $HOME/.local/bin/poetry" >&2
        exit 1
    fi
}

# Clone the ansible playbook repository from GitHub.
clone_ansible_repo() {
    git clone https://github.com/skrones/braunkrones-ansible
}

# Change into the cloned repository directory.
enter_repo() {
    cd braunkrones-ansible
}

# Initialize the poetry environment.
init_poetry() {
    if [ -f "pyproject.toml" ]; then
        poetry install
    else
        echo "No pyproject.toml found. Please verify integrity of the repository." >&2
        exit 1
    fi
}

# Run the ansible playbook.
run_ansible_system_bootstrap() {
    if ! poetry run ansible-playbook playbooks/system-bootstrap.yml --ask-become-pass --ask-vault-pass; then
        echo "Ansible playbook execution failed. Please check the output for details." >&2
        exit 1
    fi
}

# Main function to orchestrate the bootstrap process.
main() {
    check_not_root
    init_sudo
    check_for_package_manager
    install_packages
    install_poetry
    clone_ansible_repo
    enter_repo
    init_poetry
    run_ansible_system_bootstrap
    echo "Bootstrap completed successfully." >&2
}

main