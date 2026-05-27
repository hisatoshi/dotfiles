#!/bin/bash
set -e

echo "==> Installing external dependencies for Neovim config..."

# curl
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    sudo apt-get update && sudo apt-get install -y curl
fi

# unzip
if ! command -v unzip &> /dev/null; then
    echo "Installing unzip..."
    sudo apt-get install -y unzip
fi

# Git (lazy.nvimに必要)
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    sudo apt-get update && sudo apt-get install -y git
fi

# Node.js & npm (typescript-language-serverに必要)
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# ripgrep (Telescope live_grepに必要)
if ! command -v rg &> /dev/null; then
    echo "Installing ripgrep..."
    sudo apt-get install -y ripgrep
fi

# fd (Telescope find_filesで推奨)
if ! command -v fd &> /dev/null; then
    echo "Installing fd..."
    sudo apt-get install -y fd-find
    sudo ln -sf $(which fdfind) /usr/local/bin/fd 2>/dev/null || true
fi

# jq
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt-get install -y jq
fi

# lemonade (クリップボード共有)
if ! command -v lemonade &> /dev/null; then
    echo "Installing lemonade..."
    sudo apt-get install -y lemonade
fi

# win32yank (WSLクリップボード用)
if [[ $(uname -r) =~ WSL|Microsoft ]]; then
    if ! command -v win32yank.exe &> /dev/null; then
        echo "Installing win32yank for WSL..."
        curl -sLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
        unzip -p /tmp/win32yank.zip win32yank.exe > /tmp/win32yank.exe
        chmod +x /tmp/win32yank.exe
        sudo mv /tmp/win32yank.exe /usr/local/bin/
    fi
fi

# zk (Zettelkasten CLI)
if ! command -v zk &> /dev/null; then
    echo "Installing zk..."
    ZK_VERSION="0.15.4"
    curl -sL "https://github.com/zk-org/zk/releases/download/v${ZK_VERSION}/zk-v${ZK_VERSION}-linux-amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/zk /usr/local/bin/
fi

# uv (Python ツール管理)
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Python ツール（uv tool で隔離インストール、システムPythonを汚さない）
echo "Installing Python tools via uv tool..."
uv tool install pyright
uv tool install ruff

# TypeScript LSP
echo "Installing TypeScript LSP..."
sudo npm install -g typescript-language-server

# efm-langserver (json formatter用に残す場合のみ)
# brew install efm-langserver

echo "==> Done! Launch Neovim to complete plugin installation."
