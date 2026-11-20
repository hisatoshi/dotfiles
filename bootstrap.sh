#!/usr/bin/env bash
# dotfiles の配置と、設定ファイル (zsh / tmux / nvim) が前提とする外部ツールの導入を行う。
#
#   ./bootstrap.sh          link と deps を両方実行
#   ./bootstrap.sh link     シンボリックリンクの配置のみ
#   ./bootstrap.sh deps     依存ツールの導入のみ
#
# 何度実行しても同じ状態に収束する (導入済みのものはスキップする)。
# プロキシ配下では http_proxy / https_proxy を export してから実行する。
# sudo は -E 付きで呼び、プロキシ環境変数を引き継ぐ。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_VERSION="${NVIM_VERSION:-v0.12.2}"
ZK_VERSION="${ZK_VERSION:-0.15.4}"
WIN32YANK_VERSION="${WIN32YANK_VERSION:-v0.1.1}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
has()  { command -v "$1" >/dev/null 2>&1; }
is_wsl() { [[ "$(uname -r)" =~ [Mm]icrosoft|WSL ]]; }

APT_UPDATED=0
apt_install() {
    local missing=()
    for pkg in "$@"; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
    ((${#missing[@]})) || return 0
    if ((APT_UPDATED == 0)); then
        sudo -E apt-get update
        APT_UPDATED=1
    fi
    log "apt install: ${missing[*]}"
    sudo -E DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
}

# 後続のインストールで導入したコマンドをこのシェル内で使えるようにする
load_env() {
    export PATH="$HOME/.local/bin:$HOME/app:$HOME/bin:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.moon/bin:$PATH"
    local fnm_dir="$HOME/.local/share/fnm"
    if [[ -x "$fnm_dir/fnm" ]]; then
        export PATH="$fnm_dir:$PATH"
        # WSL では /run/user/$UID が無いことがあり、fnm が multishell のリンクを作れない
        if [[ -n "${XDG_RUNTIME_DIR:-}" && ! -d "$XDG_RUNTIME_DIR" ]]; then
            export XDG_RUNTIME_DIR="/tmp/runtime-$UID"
            mkdir -p -m 700 "$XDG_RUNTIME_DIR"
        fi
        eval "$(fnm env --shell bash)"
    fi
}

# ----------------------------------------------------------------------
# link: リポジトリ内の設定をホームへシンボリックリンクする
# ----------------------------------------------------------------------
link_one() {
    local src="$1" dst="$2"
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        return 0
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        local bak
        bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
        warn "$dst を $bak に退避"
        mv "$dst" "$bak"
    fi
    ln -s "$src" "$dst"
    log "link $dst -> $src"
}

do_link() {
    log "Linking dotfiles..."
    link_one "$DOTFILES_DIR/config"          "$HOME/.config"
    link_one "$DOTFILES_DIR/home/.zshrc"     "$HOME/.zshrc"
    link_one "$DOTFILES_DIR/home/.zsh"       "$HOME/.zsh"
    link_one "$DOTFILES_DIR/home/.tmux.conf" "$HOME/.tmux.conf"

    # git は 644 で checkout するが、glab は設定ファイルが 600 でないと読み込みを拒否する
    find "$DOTFILES_DIR/config/glab-cli" -maxdepth 1 -type f -name '*.yml' -exec chmod 600 {} +
}

# ----------------------------------------------------------------------
# deps: 設定ファイルが参照する外部ツール
# ----------------------------------------------------------------------
install_base() {
    # unzip: win32yank 展開 / libfuse2t64: Neovim AppImage の実行
    apt_install curl unzip git build-essential libfuse2t64
}

# Rust (sheldon のビルドに必要)。PATH は .zshenv で ~/.cargo/env を読む前提なので rc は書き換えない
install_rust() {
    if ! has cargo; then
        log "Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        # shellcheck disable=SC1091
        . "$HOME/.cargo/env"
    fi
}

# zsh: プラグインマネージャ / ディレクトリジャンプ / fuzzy finder / direnv
install_zsh_tools() {
    if ! has sheldon; then
        log "Installing sheldon..."
        cargo install sheldon --locked
    fi
    if ! has zoxide; then
        log "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi
    apt_install fzf direnv
}

# Node.js は fnm で管理する。npm のグローバル導入先は ~/.local (sudo 不要)
install_node() {
    if [[ ! -x "$HOME/.local/share/fnm/fnm" ]] && ! has fnm; then
        log "Installing fnm..."
        # .zshrc は dotfiles 側で fnm を初期化しているので rc は書き換えない
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    fi
    load_env
    if ! fnm list | grep -q 'lts-latest'; then
        log "Installing Node.js LTS..."
        fnm install --lts
    fi
    fnm default lts-latest
    fnm use lts-latest >/dev/null
    if [[ "$(npm config get prefix)" != "$HOME/.local" ]]; then
        npm config set prefix "$HOME/.local"
    fi
}

npm_global() {
    local pkg="$1" bin="${2:-$1}"
    has "$bin" && return 0
    log "npm install -g $pkg"
    npm install -g "$pkg"
}

# .zshrc が `go env GOPATH` を参照し、lemonade / md2pdf も go install で入れる
install_go() {
    has go || apt_install golang-go
}

install_uv() {
    if ! has uv; then
        log "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    fi
}

uv_tool() {
    local pkg="$1"
    uv tool list 2>/dev/null | grep -q "^$pkg " && return 0
    log "uv tool install $pkg"
    uv tool install "$pkg"
}

# Neovim 本体 (AppImage を ~/app/nvim に置く。.zshrc が ~/app を PATH に入れる)
# 導入した版は ~/app/.nvim-version に記録する (AppImage は FUSE が無いと --version も実行できない)
install_neovim() {
    local stamp="$HOME/app/.nvim-version"
    if [[ -x "$HOME/app/nvim" && "$(cat "$stamp" 2>/dev/null)" == "$NVIM_VERSION" ]]; then
        return 0
    fi
    log "Installing Neovim $NVIM_VERSION..."
    mkdir -p "$HOME/app"
    curl -fsSLo "$HOME/app/nvim.tmp" \
        "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.appimage"
    chmod +x "$HOME/app/nvim.tmp"
    mv "$HOME/app/nvim.tmp" "$HOME/app/nvim"
    echo "$NVIM_VERSION" >"$stamp"
}

# Neovim が使う外部コマンド (Telescope / LSP / クリップボード)
install_neovim_deps() {
    apt_install ripgrep fd-find jq
    # Ubuntu の fd-find はコマンド名が fdfind なので fd として呼べるようにする
    if ! has fd && has fdfind; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi

    # LSP: pyright / ruff / typescript-language-server
    uv_tool pyright
    uv_tool ruff
    npm_global typescript tsc
    npm_global typescript-language-server

    # LSP: moon-lsp (MoonBit ツールチェーンに同梱。古い版では moonbit-lsp)。
    # インストーラは $SHELL の rc に PATH を追記するので、SHELL=/bin/sh で追記を抑止する
    # (.zshrc は ~/.moon/bin を PATH に入れている)
    if [[ ! -x "$HOME/.moon/bin/moon" ]]; then
        log "Installing MoonBit toolchain..."
        curl -fsSL https://cli.moonbitlang.com/install/unix.sh | SHELL=/bin/sh bash
    fi

    # クリップボード共有: lemonade (systemd --user で常駐。unit は config/systemd/user にある)
    if ! has lemonade; then
        log "Installing lemonade..."
        go install github.com/lemonade-command/lemonade@latest
    fi
    if systemctl --user show-environment >/dev/null 2>&1; then
        systemctl --user daemon-reload
        systemctl --user enable --now lemonade.service || warn "lemonade.service を起動できませんでした"
    else
        warn "systemd --user が使えないため lemonade.service は次回ログイン後に 'systemctl --user enable --now lemonade' で有効化する"
    fi

    # WSL のクリップボード: win32yank
    if is_wsl && ! has win32yank.exe; then
        log "Installing win32yank..."
        local tmp
        tmp="$(mktemp -d)"
        curl -fsSLo "$tmp/win32yank.zip" \
            "https://github.com/equalsraf/win32yank/releases/download/${WIN32YANK_VERSION}/win32yank-x64.zip"
        unzip -p "$tmp/win32yank.zip" win32yank.exe >"$tmp/win32yank.exe"
        chmod +x "$tmp/win32yank.exe"
        sudo mv "$tmp/win32yank.exe" /usr/local/bin/
        rm -rf "$tmp"
    fi
}

# Zettelkasten CLI (補完は home/.zsh/completion/_zk)
install_zk() {
    has zk && return 0
    log "Installing zk $ZK_VERSION..."
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/zk-org/zk/releases/download/v${ZK_VERSION}/zk-v${ZK_VERSION}-linux-amd64.tar.gz" | tar xz -C "$tmp"
    sudo install -m 755 "$tmp/zk" /usr/local/bin/zk
    rm -rf "$tmp"
}

# Markdown -> PDF (md2pdf) と図のレンダリング
install_md2pdf_deps() {
    npm_global @mermaid-js/mermaid-cli mmdc

    # Playwright + Chromium (PDF 生成)。OS 依存ライブラリは sudo -E で入れてプロキシを通す
    uv_tool playwright
    if ! compgen -G "$HOME/.cache/ms-playwright/chromium-*" >/dev/null; then
        log "Installing Playwright Chromium..."
        sudo -E env "PATH=$PATH" playwright install-deps chromium
        playwright install chromium
    fi

    apt_install fonts-noto-cjk

    if ! has md2pdf; then
        log "Installing md2pdf..."
        go install github.com/135yshr/md2pdf/cmd/md2pdf@latest
    fi
}

do_deps() {
    log "Installing external dependencies for dotfiles..."
    load_env
    install_base
    install_rust
    install_go
    install_uv
    install_node
    install_zsh_tools
    install_neovim
    install_neovim_deps
    install_zk
    install_md2pdf_deps
    log "Done. Launch Neovim once to complete plugin installation (lazy.nvim / treesitter)."
}

case "${1:-all}" in
    link) do_link ;;
    deps) do_deps ;;
    all)  do_link; do_deps ;;
    *)    echo "usage: $0 [link|deps|all]" >&2; exit 1 ;;
esac
