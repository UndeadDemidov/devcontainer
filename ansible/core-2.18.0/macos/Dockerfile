# Ubuntu-based DevContainer for Python/Ansible Development
# Optimized for security, performance, and VS Code compatibility

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS builder

# Install build dependencies and system utilities
RUN apt-get update && apt-get install -y \
    build-essential \
    ca-certificates \
    sudo gnupg \
    software-properties-common \
    libonig-dev \
    git-crypt \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

# Install UV package manager (10-100x faster than pip)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install Python 3.12 (stable for production)
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y python3.12 python3.12-venv python3.12-dev \
    && rm -rf /var/lib/apt/lists/*

# Create Python virtual environment
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages using UV for speed
RUN uv pip install \
    ansible-core==2.18.0 \
    ansible-lint==25.6.1 \
    ansible-navigator

# Create non-root user with proper permissions for macOS
ARG USERNAME=vscode
ARG USER_UID=501
ARG USER_GID=20

RUN usermod -u ${USER_UID} ${USERNAME} \
    && usermod -g ${USER_GID} ${USERNAME} \
    && usermod -aG ${USER_GID} ${USERNAME} \
    && chown -R ${USER_UID}:${USER_GID} /home/${USERNAME} \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/nopasswd > /dev/null \
    && chmod 0440 /etc/sudoers.d/nopasswd

# RUN groupmod --gid $USER_GID -o $GROUPNAME \
#     && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
#     && chown -R $USER_UID:$USER_GID /home/$USERNAME

COPY . /home/vscode/
RUN chmod +x /home/vscode/ansible-ctx.sh && \
    echo "source /home/vscode/ansible-ctx.sh" >> /home/vscode/.bashrc && \
    chmod +x /home/vscode/aliases.sh && \
    echo "source /home/vscode/aliases.sh" >> /home/vscode/.bashrc && \
    chmod +x /home/vscode/cdp.sh && \
    echo "source /home/vscode/cdp.sh" >> /home/vscode/.bashrc && \
    echo "source /home/vscode/ansible-ctx.sh" >> /home/vscode/.zshrc && \
    echo "source /home/vscode/aliases.sh" >> /home/vscode/.zshrc && \
    echo "source /home/vscode/cdp.sh" >> /home/vscode/.zshrc

USER $USERNAME

# Set working directory
# RUN mkdir -p /workspace
# WORKDIR /workspace

# Configure git safe directory
RUN git config --global --add safe.directory /workspace

ENV GIT_DISCOVERY_ACROSS_FILESYSTEM=1

CMD ["/bin/bash"]