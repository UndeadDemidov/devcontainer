# DevContainer Images Collection

A collection of optimized Docker images for use with **DevContainer** and **VS Code**.

## Description

This repository contains ready-to-use Docker images specifically configured for working in the VS Code development environment with the DevContainer extension. The images are optimized for:

- 🚀 **Performance** - fast build and startup
- 🔒 **Security** - minimal privileges, updated dependencies
- 🛠️ **Compatibility** - full integration with VS Code and DevContainer
- 📦 **Ready to use** - pre-installed tools and configurations

## Available Images

### Ansible Core 2.18.0 (macOS)
- **Path**: `ansible/core-2.18.0/macos/`
- **Base**: Ubuntu 22.04
- **Python**: 3.12
- **Package Manager**: UV (10-100x faster than pip)
- **Tools**: ansible-core, ansible-lint, ansible-navigator
- **Additional Features**: ansible-ctx, cdp, aliases

## Usage

1. Clone the repository
2. Choose the desired image from the collection
3. Use the Dockerfile as a base for your `.devcontainer/devcontainer.json`

### Example devcontainer.json

```json
{
  "name": "Ansible Development",
  "build": {
    "dockerfile": "../ansible/core-2.18.0/macos/Dockerfile"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.ansible"
      ]
    }
  }
}
```

## Features

- ✅ Automatic user configuration for macOS
- ✅ VS Code DevContainer integration
- ✅ Pre-installed development tools
- ✅ Optimized security settings
- ✅ Python virtual environment support

## License

See the [LICENSE](LICENSE) file for detailed information.
