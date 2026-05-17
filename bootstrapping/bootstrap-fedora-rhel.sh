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
    "git"
    "python"
    "pipx"
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

install_poetry() {
    if ! command -v poetry >/dev/null 2>&1; then
        echo "Installing poetry..." >&2
        pipx install poetry
    else
        echo "poetry is already installed." >&2
    fi
}

clone_ansible_repo() {
    git clone https://github.com/skrones/braunkrones-ansible
}

enter_repo() {
    cd braunkrones-ansible
}

init_poetry() {
    if [ -f "pyproject.toml" ]; then
        poetry install
    else
        echo "No pyproject.toml found. Please verify integrity of the repository." >&2
        exit 1
    fi
}

run_ansible_system_bootstrap() {
    if ! poetry run ansible-playbook playbooks/system-bootstrap.yml --ask-become-pass --ask-vault-pass; then
        echo "Ansible playbook execution failed. Please check the output for details." >&2
        exit 1
    fi
}

main() {
    check_for_privledged_user
    check_for_package_manager
    install_packages
    install_poetry
    clone_ansible_repo
    enter_repo
    init_poetry
    run_ansible_system_bootstrap
    echo "Bootstrap completed successfully." >&2
}

main()

