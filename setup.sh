#!/bin/bash
#
# Set up Tmux configuration using Oh My Tmux
# Installs oh-my-tmux and applies local customizations
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OH_MY_TMUX_DIR="$HOME/.tmux/oh-my-tmux"

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

# Backup existing file
backup_if_exists() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up $target to $backup"
        mv "$target" "$backup"
    fi
}

# Create tmux directories
create_tmux_directories() {
    info "Creating tmux directories..."
    mkdir -p ~/.tmux/plugins
    mkdir -p ~/.config/tmux-which-key
}

# Install Oh My Tmux
install_oh_my_tmux() {
    info "Checking Oh My Tmux..."
    if [[ -d "$OH_MY_TMUX_DIR" ]]; then
        info "Oh My Tmux already installed."
    else
        info "Installing Oh My Tmux..."
        git clone https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX_DIR"
        info "Oh My Tmux installed."
    fi
}

# Install tmux plugin manager
install_tpm() {
    info "Checking tmux plugin manager..."
    local tpm_path="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_path" ]]; then
        info "tpm already installed."
    else
        info "Installing tpm (tmux plugin manager)..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_path"
        info "tpm installed."
    fi
}

# Install tmux config
install_tmux_config() {
    local use_symlink="$1"

    info "Installing tmux configuration..."

    # Create wrapper ~/.tmux.conf that sources oh-my-tmux and .local
    # This allows tpm to detect the source-file directive for .local
    backup_if_exists ~/.tmux.conf
    cat > ~/.tmux.conf << 'EOF'
# Wrapper config - sources oh-my-tmux and local customizations
# This structure allows tpm to detect plugins in .tmux.conf.local

# Source oh-my-tmux
source-file ~/.tmux/oh-my-tmux/.tmux.conf

# Source local customizations (tpm detects this for plugin scanning)
source-file ~/.tmux.conf.local
EOF
    info "  Created: ~/.tmux.conf (wrapper)"

    # Install local customizations
    backup_if_exists ~/.tmux.conf.local
    if [[ "$use_symlink" == "true" ]]; then
        ln -sf "$SCRIPT_DIR/tmux.conf.local" ~/.tmux.conf.local
        info "  Linked: ~/.tmux.conf.local"
    else
        cp "$SCRIPT_DIR/tmux.conf.local" ~/.tmux.conf.local
        info "  Copied: ~/.tmux.conf.local"
    fi

    # Install tmux-which-key config
    local whichkey_config="$HOME/.config/tmux-which-key/config.yaml"
    backup_if_exists "$whichkey_config"
    if [[ "$use_symlink" == "true" ]]; then
        ln -sf "$SCRIPT_DIR/tmux-which-key.yaml" "$whichkey_config"
        info "  Linked: $whichkey_config"
    else
        cp "$SCRIPT_DIR/tmux-which-key.yaml" "$whichkey_config"
        info "  Copied: $whichkey_config"
    fi
}

# Install tmux plugins via tpm
install_tmux_plugins() {
    info "Installing tmux plugins..."
    local tpm_path="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_path" ]]; then
        # Set TMUX_PLUGIN_MANAGER_PATH for tpm (needed when running outside tmux)
        tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
        "$tpm_path/bin/install_plugins"
        info "Plugins installed."
    else
        warn "tpm not installed. Skipping plugin installation."
        warn "Run 'make deps-tpm' to install tpm, then 'make plugins'"
    fi
}

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --symlink      Use symlinks instead of copying files"
    echo "  --no-plugins   Skip plugin installation"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --symlink"
    echo "  $0 --no-plugins"
    echo ""
    echo "This script will:"
    echo "  1. Create required directories"
    echo "  2. Install Oh My Tmux"
    echo "  3. Install tpm plugin manager"
    echo "  4. Install tmux configuration"
    echo "  5. Install plugins via tpm"
}

# Main
main() {
    local use_symlink=false
    local skip_plugins=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --symlink)
                use_symlink=true
                shift
                ;;
            --no-plugins)
                skip_plugins=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    echo "========================================"
    echo "Tmux Configuration Setup (Oh My Tmux)"
    echo "========================================"
    echo ""

    create_tmux_directories
    install_oh_my_tmux
    install_tpm
    install_tmux_config "$use_symlink"

    if ! $skip_plugins; then
        install_tmux_plugins
    else
        warn "Skipping plugin installation."
        warn "Run 'tmux' then press prefix + I to install plugins manually."
    fi

    echo ""
    info "Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Start or restart tmux"
    echo "  2. Press prefix + I to install plugins (if skipped)"
    echo "  3. Press prefix + r to reload config"
    echo ""
    echo "Key bindings (Oh My Tmux defaults):"
    echo "  C-a         Secondary prefix (C-b still works)"
    echo "  <prefix> e  Edit local config"
    echo "  <prefix> r  Reload config"
    echo "  <prefix> m  Toggle mouse mode"
    echo "  <prefix> +  Maximize pane to new window"
    echo "  h/j/k/l     Navigate panes (vim-style)"
}

main "$@"
