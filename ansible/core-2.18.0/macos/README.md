# Ansible Core 2.18.0 DevContainer (macOS)

Optimized Docker image for Ansible development in VS Code DevContainer environment, specifically configured for macOS.

## Image Description

### Technical Specifications
- **Base**: Ubuntu 22.04 (mcr.microsoft.com/devcontainers/base:ubuntu-22.04)
- **Python**: 3.12 (stable version for production)
- **Package Manager**: UV (10-100x faster than pip)
- **Ansible**: core 2.18.0
- **Additional Tools**: ansible-lint, ansible-navigator

### Features
- ✅ Automatic user configuration for macOS (UID: 501, GID: 20)
- ✅ Python virtual environment in `/opt/venv`
- ✅ VS Code DevContainer integration
- ✅ Pre-installed useful scripts and aliases

## Built-in Tools

### ansible-ctx - Ansible Context Switcher

Interactive tool for managing Ansible project contexts.

#### Main commands:
```bash
# Show current status
ansible-ctx

# List available contexts
ansible-ctx list

# Switch to context
ansible-ctx use <context_name>

# Create new context
ansible-ctx create <context_name> <inventory_path>

# Remove context
ansible-ctx remove <context_name>

# Auto-scan inventories/
ansible-ctx scan
```

#### Features:
- 🎯 **Automatic project detection** - looks for `.git`, `ansible.cfg` or `inventories` folder
- 📁 **Inventories scanning** - automatically finds available contexts
- 🌈 **Colored output** - convenient status visualization
- 💾 **Global storage** - contexts are saved in `~/.ansible/contexts`
- 🔄 **Project switching** - support for multiple projects

#### Usage example:
```bash
# In project with inventories/dev, inventories/staging, inventories/prod
$ ansible-ctx list
Project: my-ansible-project (/workspace)
Available contexts:
    dev -> /workspace/inventories/dev/
  ► staging -> /workspace/inventories/staging/ (active)
    prod -> /workspace/inventories/prod/

$ ansible-ctx use prod
Switched to context: prod
```

### cdp - Interactive Directory Navigation

Interactive tool for quick directory navigation with search.

#### Usage:
```bash
# Start interactive navigation
cdp
```

#### Capabilities:
- ⌨️ **Keyboard control** - arrows, Enter, Backspace
- 🔍 **Real-time search** - filter directories by input
- 📱 **Adaptive interface** - adjusts to terminal size
- ⚡ **Fast navigation** - instant directory switching
- 🔄 **Return to original directory** - Ctrl+C restores original position

#### Controls:
- **↑/↓** - navigate through list
- **Enter** - enter selected directory
- **Backspace** - delete search character
- **Ctrl+C** - cancel and return to original directory

### aliases.sh - Useful Aliases

Set of pre-installed aliases for convenient Ansible work.

#### Available aliases:
```bash
# Quick Ansible commands
alias ap='ansible-playbook'
alias av='ansible-vault'
alias ag='ansible-galaxy'
alias al='ansible-lint'

# Project navigation
alias cdans='cd /workspace'
alias cdinv='cd /workspace/inventories'

# Context work
alias ctx='ansible-ctx'
alias ctxl='ansible-ctx list'
alias ctxs='ansible-ctx scan'
```

## DevContainer Usage

### devcontainer.json
```json
{
  "name": "Ansible Development",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.ansible",
        "redhat.ansible"
      ]
    }
  },
  "features": {
    "ghcr.io/devcontainers/features/git:1": {}
  },
  "postCreateCommand": "echo 'Ansible development environment ready!'"
}
```

### Project Structure
```
project/
├── .devcontainer/
│   └── devcontainer.json
├── inventories/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── playbooks/
├── roles/
└── ansible.cfg
```

## Security

- 🔐 Non-privileged user `vscode`
- 🛡️ Configured sudo rights without password
- 🔒 Updated system packages
- 🚫 Minimal set of installed packages

## Performance

- ⚡ UV package manager (10-100x faster than pip)
- 🐍 Python 3.12 virtual environment
- 📦 Optimized image size
- 🔄 Fast build with layer caching

## Support

The image is tested and optimized for:
- ✅ macOS (primary platform)
- ✅ VS Code DevContainer
- ✅ Ansible Core 2.18.0
- ✅ Python 3.12
- ✅ Ubuntu 22.04 