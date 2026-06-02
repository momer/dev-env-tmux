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
    mkdir -p ~/.tmux/scripts
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

    # Install local customizations first (needed before plugin install)
    backup_if_exists ~/.tmux.conf.local
    if [[ "$use_symlink" == "true" ]]; then
        ln -sf "$SCRIPT_DIR/tmux.conf.local" ~/.tmux.conf.local
        info "  Linked: ~/.tmux.conf.local"
    else
        cp "$SCRIPT_DIR/tmux.conf.local" ~/.tmux.conf.local
        info "  Copied: ~/.tmux.conf.local"
    fi

    # Create temporary wrapper for tpm plugin detection
    # This will be replaced with symlink after plugin install
    backup_if_exists ~/.tmux.conf
    cat > ~/.tmux.conf << 'EOF'
# Temporary wrapper for tpm plugin detection
source-file ~/.tmux/oh-my-tmux/.tmux.conf
source-file ~/.tmux.conf.local
EOF
    info "  Created: ~/.tmux.conf (temporary for plugin install)"

    # Install custom scripts
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        info "  Installing scripts..."
        cp "$SCRIPT_DIR/scripts/"*.sh ~/.tmux/scripts/ 2>/dev/null || true
        chmod +x ~/.tmux/scripts/*.sh 2>/dev/null || true
    fi
}

# Finalize tmux config (replace wrapper with symlink or copy)
finalize_tmux_config() {
    local use_symlink="$1"

    info "Finalizing tmux configuration..."
    if [[ "$use_symlink" == "true" ]]; then
        ln -sf "$OH_MY_TMUX_DIR/.tmux.conf" ~/.tmux.conf
        info "  Linked: ~/.tmux.conf -> oh-my-tmux"
    else
        cp "$OH_MY_TMUX_DIR/.tmux.conf" ~/.tmux.conf
        info "  Copied: ~/.tmux.conf"
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

# Install tmux-which-key config
#
# The plugin's XDG mode is disabled (see tmux.conf.local) because it depends on
# GNU `realpath --relative-to`, which macOS's BSD realpath rejects. With XDG off,
# the plugin reads config.yaml from its own directory. That directory is managed
# by tpm, and config.yaml is gitignored upstream, so this must run *after* the
# plugin is cloned (otherwise the pre-existing file would block tpm's git clone)
# and the config survives future plugin updates.
install_whichkey_config() {
    local use_symlink="$1"
    local plugin_dir="$HOME/.tmux/plugins/tmux-which-key"
    local whichkey_config="$plugin_dir/config.yaml"

    info "Installing tmux-which-key config..."

    if [[ ! -d "$plugin_dir" ]]; then
        warn "tmux-which-key plugin not installed yet; skipping config."
        warn "After installing plugins (prefix + I or 'make plugins'), run:"
        warn "  make update-config"
        return
    fi

    backup_if_exists "$whichkey_config"
    if [[ "$use_symlink" == "true" ]]; then
        ln -sf "$SCRIPT_DIR/tmux-which-key.yaml" "$whichkey_config"
        info "  Linked: $whichkey_config"
    else
        cp "$SCRIPT_DIR/tmux-which-key.yaml" "$whichkey_config"
        info "  Copied: $whichkey_config"
    fi

    # Pre-generate the menu so the binding works immediately, without waiting for
    # the next tmux start. Best-effort: the plugin also rebuilds on every startup.
    local build="$plugin_dir/plugin/build.py"
    local init="$plugin_dir/plugin/init.tmux"
    if [[ -f "$build" ]] && command -v python3 >/dev/null 2>&1; then
        if python3 "$build" "$whichkey_config" "$init" >/dev/null 2>&1; then
            info "  Generated: $init"
            # Apply to a running server if one exists.
            tmux source-file "$init" 2>/dev/null || true
        fi
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

    # Install which-key config after plugins so its directory exists (tpm-managed)
    install_whichkey_config "$use_symlink"

    # Replace temporary wrapper with proper symlink/copy to oh-my-tmux
    finalize_tmux_config "$use_symlink"

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
