#!/bin/bash
#
# Install external dependencies for Tmux environment
# Supports: macOS, Linux
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

OS="$(detect_os)"

is_macos() {
    [[ "$OS" == "macos" ]]
}

is_linux() {
    [[ "$OS" == "linux" ]]
}

# Check if a command exists
check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Install tmux
install_tmux() {
    info "Installing tmux..."

    if check_cmd tmux; then
        info "tmux is already installed: $(tmux -V)"
        return
    fi

    if is_macos && check_cmd brew; then
        brew install tmux
    elif is_linux && check_cmd apt; then
        sudo apt update && sudo apt install -y tmux
    elif is_linux && check_cmd dnf; then
        sudo dnf install -y tmux
    elif is_linux && check_cmd pacman; then
        sudo pacman -S --noconfirm tmux
    else
        warn "No supported package manager found. Install tmux manually:"
        warn "  https://github.com/tmux/tmux/wiki/Installing"
    fi
}

# Install tmux plugin manager
install_tpm() {
    info "Installing tmux plugin manager (tpm)..."

    local tpm_path="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_path" ]]; then
        info "tpm is already installed."
        return
    fi

    if ! check_cmd git; then
        error "git is required to install tpm. Install git first."
        return 1
    fi

    mkdir -p ~/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm "$tpm_path"
    info "tpm installed successfully."
    echo ""
    echo "To install plugins:"
    echo "  1. Start tmux"
    echo "  2. Press prefix + I (capital i)"
}

# Check status of all tools
check_status() {
    echo ""
    info "Checking tool status..."
    echo ""

    echo "Tmux:"
    if check_cmd tmux; then
        echo "  ✓ tmux $(tmux -V | cut -d' ' -f2)"
    else
        echo "  ✗ tmux"
    fi
    echo ""

    echo "Oh My Tmux:"
    if [[ -d "$HOME/.tmux/oh-my-tmux" ]]; then
        echo "  ✓ oh-my-tmux installed"
    else
        echo "  ✗ oh-my-tmux not installed"
    fi
    echo ""

    echo "Tmux Plugin Manager:"
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        echo "  ✓ tpm installed"
    else
        echo "  ✗ tpm not installed"
    fi
    echo ""

    echo "Tmux Configuration:"
    if [[ -f "$HOME/.tmux.conf" ]]; then
        echo "  ✓ ~/.tmux.conf exists"
    else
        echo "  ✗ ~/.tmux.conf not found"
    fi
    if [[ -f "$HOME/.tmux.conf.local" ]]; then
        echo "  ✓ ~/.tmux.conf.local exists"
    else
        echo "  ✗ ~/.tmux.conf.local not found"
    fi
    echo ""

    echo "Installed Plugins:"
    local plugin_dir="$HOME/.tmux/plugins"
    if [[ -d "$plugin_dir" ]]; then
        for dir in "$plugin_dir"/*/; do
            if [[ -d "$dir" ]]; then
                local name=$(basename "$dir")
                echo "  ✓ $name"
            fi
        done
    else
        echo "  No plugins directory found"
    fi
    echo ""
}

# Main
main() {
    echo "========================================"
    echo "Tmux Environment Dependencies"
    echo "========================================"
    echo ""

    case "${1:-all}" in
        tmux)
            install_tmux
            ;;
        tpm)
            install_tpm
            ;;
        status|check)
            check_status
            ;;
        all)
            install_tmux
            echo ""
            install_tpm
            echo ""
            check_status
            ;;
        *)
            echo "Usage: $0 [tmux|tpm|status|all]"
            echo ""
            echo "Options:"
            echo "  tmux     Install tmux"
            echo "  tpm      Install tmux plugin manager"
            echo "  status   Check installation status"
            echo "  all      Install all dependencies (default)"
            exit 1
            ;;
    esac

    info "Done!"
}

main "$@"
