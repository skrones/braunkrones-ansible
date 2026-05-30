# Fedora/RHEL

```bash
curl -fsSL https://raw.githubusercontent.com/skrones/braunkrones-ansible/refs/heads/re-work-development/bootstrapping/bootstrap-fedora-rhel.sh | bash
```

The bootstrap script installs Python dependencies with Poetry, installs Ansible Galaxy dependencies from `requirements.yml`, and then runs the system bootstrap playbook.