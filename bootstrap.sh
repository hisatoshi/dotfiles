#!/bin/bash
set -e

echo "==> Installing external dependencies for Neovim config..."

# apt パッケージをまとめてインストール
APT_PACKAGES=()

command -v curl    &>/dev/null || APT_PACKAGES+=(curl)
command -v unzip   &>/dev/null || APT_PACKAGES+=(unzip)
command -v python3 &>/dev/null || APT_PACKAGES+=(python3 python3-pip)
command -v git     &>/dev/null || APT_PACKAGES+=(git)
command -v rg      &>/dev/null || APT_PACKAGES+=(ripgrep)
command -v jq      &>/dev/null || APT_PACKAGES+=(jq)
dpkg -s fd-find &>/dev/null 2>&1 || APT_PACKAGES+=(fd-find)
command -v lemonade &>/dev/null || APT_PACKAGES+=(lemonade)

if [ ${#APT_PACKAGES[@]} -gt 0 ]; then
    echo "Installing apt packages: ${APT_PACKAGES[*]}"
    sudo apt-get update
    sudo apt-get install -y "${APT_PACKAGES[@]}"
fi

# fd のシンボリックリンク
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# Node.js (typescript-language-server に必要)
if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# uv (Python ツール管理)
if ! command -v uv &>/dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Python ツール（uv tool で隔離インストール）
echo "Installing Python tools via uv tool..."
uv tool install pyright
uv tool install ruff

# TypeScript LSP
echo "Installing TypeScript LSP..."
sudo npm install -g typescript-language-server

echo "==> Done! Launch Neovim to complete plugin installation."
