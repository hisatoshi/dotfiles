#!/bin/bash
set -e

echo "==> Installing external dependencies for Neovim config..."

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

# Python & pip (pyright, flake8, blackに必要)
if ! command -v python3 &> /dev/null; then
    echo "Installing Python..."
    sudo apt-get install -y python3 python3-pip
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

# jq (efm json formatterに必要)
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt-get install -y jq
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

# LSP & Linter/Formatter
echo "Installing LSP servers and formatters..."
sudo npm install -g pyright typescript-language-server efm-langserver
pip3 install --user flake8 black

echo "==> Done! Launch Neovim to complete plugin installation."
