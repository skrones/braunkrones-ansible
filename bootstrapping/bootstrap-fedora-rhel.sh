#!/bin/bash
#
# Bootstrap script automating the initial configuration of a Fedora/RHEL machine for ansible management & control.

check_for_privledged_user() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root or with sudo privileges." >&2
        exit 1
    fi
}

check_for_package_manager() {
    if command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
    else
        echo "No supported package manager found." >&2
        exit 1
    fi
}

packages=(
    "ansible"
    "git"
    "python"
)

install_packages() {
    for package in "${packages[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            echo "Installing $package..." >&2
            $PACKAGE_MANAGER install -y "$package"
        else
            echo "$package is already installed." >&2
        fi
    done
}

clone_ansible_repo() {
    git clone https://github.com/skrones/braunkrones-ansible
}

main() {
    check_for_privledged_user
    check_for_package_manager
    install_packages
    clone_ansible_repo
    echo "Bootstrap completed successfully." >&2
}

main

