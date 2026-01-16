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

# Portable in-place sed (macOS requires '' after -i)
sed_i() {
    if is_macos; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
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

# Install fzf (required for tmux-fzf plugin)
install_fzf() {
    info "Installing fzf..."

    if check_cmd fzf; then
        info "fzf is already installed: $(fzf --version | head -1)"
        return
    fi

    if is_macos && check_cmd brew; then
        brew install fzf
    elif is_linux && check_cmd apt; then
        sudo apt update && sudo apt install -y fzf
    elif is_linux && check_cmd dnf; then
        sudo dnf install -y fzf
    elif is_linux && check_cmd pacman; then
        sudo pacman -S --noconfirm fzf
    else
        warn "No supported package manager found. Install fzf manually:"
        warn "  https://github.com/junegunn/fzf#installation"
    fi
}

# Check if a Nerd Font is installed
check_nerd_font() {
    local font_name="$1"
    # Check in font directories (Linux)
    if [[ -d "$HOME/.local/share/fonts" ]]; then
        find "$HOME/.local/share/fonts" -iname "*${font_name}*Nerd*" 2>/dev/null | grep -q . && return 0
    fi
    if [[ -d "/usr/share/fonts" ]]; then
        find /usr/share/fonts -iname "*${font_name}*Nerd*" 2>/dev/null | grep -q . && return 0
    fi
    # Check in system and user font directories (macOS)
    if [[ -d "/Library/Fonts" ]]; then
        find /Library/Fonts -iname "*${font_name}*Nerd*" 2>/dev/null | grep -q . && return 0
    fi
    if [[ -d "$HOME/Library/Fonts" ]]; then
        find "$HOME/Library/Fonts" -iname "*${font_name}*Nerd*" 2>/dev/null | grep -q . && return 0
    fi
    # Check via brew cask (macOS)
    if check_cmd brew; then
        brew list --cask 2>/dev/null | grep -qi "font-.*nerd-font" && return 0
    fi
    return 1
}

# List installed Nerd Fonts
list_installed_nerd_fonts() {
    local fonts=()

    # Check brew casks (macOS)
    if check_cmd brew; then
        while IFS= read -r font; do
            fonts+=("$font (brew)")
        done < <(brew list --cask 2>/dev/null | grep -i "font-.*nerd-font" || true)
    fi

    # Check font directories (macOS)
    if [[ -d "$HOME/Library/Fonts" ]]; then
        while IFS= read -r font; do
            [[ -n "$font" ]] && fonts+=("$(basename "$font")")
        done < <(find "$HOME/Library/Fonts" -iname "*Nerd*" -type f 2>/dev/null | head -5 || true)
    fi

    # Check font directories (Linux)
    if [[ -d "$HOME/.local/share/fonts" ]]; then
        while IFS= read -r font; do
            [[ -n "$font" ]] && fonts+=("$(basename "$font")")
        done < <(find "$HOME/.local/share/fonts" -iname "*Nerd*" -type f 2>/dev/null | head -5 || true)
    fi
    if [[ -d "/usr/share/fonts" ]]; then
        while IFS= read -r font; do
            [[ -n "$font" ]] && fonts+=("$(basename "$font")")
        done < <(find /usr/share/fonts -iname "*Nerd*" -type f 2>/dev/null | head -5 || true)
    fi

    if [[ ${#fonts[@]} -gt 0 ]]; then
        printf '%s\n' "${fonts[@]}" | sort -u | head -5
    fi
}

# Download and install Nerd Font on Linux
download_nerd_font_linux() {
    local font_name="$1"
    local font_zip="$2"
    local font_dir="$HOME/.local/share/fonts"
    local tmp_dir="/tmp/nerd-font-$$"

    mkdir -p "$font_dir"

    info "Downloading $font_name from GitHub..."
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_zip}.zip"

    if ! check_cmd curl && ! check_cmd wget; then
        error "curl or wget required to download fonts"
        return 1
    fi

    mkdir -p "$tmp_dir"
    if check_cmd curl; then
        curl -fsSL "$url" -o "$tmp_dir/font.zip" || { error "Download failed"; rm -rf "$tmp_dir"; return 1; }
    else
        wget -q "$url" -O "$tmp_dir/font.zip" || { error "Download failed"; rm -rf "$tmp_dir"; return 1; }
    fi

    info "Installing to $font_dir..."
    unzip -q "$tmp_dir/font.zip" -d "$tmp_dir/extracted" 2>/dev/null || { error "Unzip failed"; rm -rf "$tmp_dir"; return 1; }

    find "$tmp_dir/extracted" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} "$font_dir/" \;

    rm -rf "$tmp_dir"

    if check_cmd fc-cache; then
        info "Updating font cache..."
        fc-cache -fv >/dev/null 2>&1
    fi

    info "$font_name installed successfully!"
    return 0
}

# Configure tmux separator style
configure_separators() {
    local style="$1"  # "powerline" or "ascii"
    local config_file="$HOME/.tmux.conf.local"

    if [[ ! -f "$config_file" ]]; then
        warn "~/.tmux.conf.local not found. Run 'make setup' first."
        return 1
    fi

    info "Configuring separator style: $style"

    if [[ "$style" == "powerline" ]]; then
        # Uncomment powerline separator lines
        sed_i "s/^# tmux_conf_theme_left_separator_main/tmux_conf_theme_left_separator_main/" "$config_file"
        sed_i "s/^# tmux_conf_theme_left_separator_sub/tmux_conf_theme_left_separator_sub/" "$config_file"
        sed_i "s/^# tmux_conf_theme_right_separator_main/tmux_conf_theme_right_separator_main/" "$config_file"
        sed_i "s/^# tmux_conf_theme_right_separator_sub/tmux_conf_theme_right_separator_sub/" "$config_file"
    else
        # Set ASCII separators (empty = oh-my-tmux default squares, or use simple chars)
        sed_i "s/^# tmux_conf_theme_left_separator_main=.*/tmux_conf_theme_left_separator_main=''/" "$config_file"
        sed_i "s/^# tmux_conf_theme_left_separator_sub=.*/tmux_conf_theme_left_separator_sub='|'/" "$config_file"
        sed_i "s/^# tmux_conf_theme_right_separator_main=.*/tmux_conf_theme_right_separator_main=''/" "$config_file"
        sed_i "s/^# tmux_conf_theme_right_separator_sub=.*/tmux_conf_theme_right_separator_sub='|'/" "$config_file"
        # Also handle if already uncommented
        sed_i "s/^tmux_conf_theme_left_separator_main=.*/tmux_conf_theme_left_separator_main=''/" "$config_file"
        sed_i "s/^tmux_conf_theme_left_separator_sub=.*/tmux_conf_theme_left_separator_sub='|'/" "$config_file"
        sed_i "s/^tmux_conf_theme_right_separator_main=.*/tmux_conf_theme_right_separator_main=''/" "$config_file"
        sed_i "s/^tmux_conf_theme_right_separator_sub=.*/tmux_conf_theme_right_separator_sub='|'/" "$config_file"
    fi

    info "Updated ~/.tmux.conf.local"
    echo "Reload tmux config with: tmux source-file ~/.tmux.conf"
}

# Prompt for separator style
prompt_separator_style() {
    local has_font="$1"  # "true" if font was installed/exists

    echo ""
    echo "Status bar separator style:"
    if [[ "$has_font" == "true" ]]; then
        echo "  1) Powerline symbols (recommended - uses installed Nerd Font)"
        echo "  2) Plain ASCII (works without special fonts)"
    else
        echo "  1) Powerline symbols (requires a Nerd Font)"
        echo "  2) Plain ASCII (recommended - no special font needed)"
    fi
    echo "  3) Skip (keep current setting)"
    echo ""
    read -p "Select option [1-3]: " choice

    case "$choice" in
        1) configure_separators "powerline" ;;
        2) configure_separators "ascii" ;;
        *) info "Keeping current separator settings." ;;
    esac
}

# Install Nerd Font (interactive prompt)
install_nerd_font() {
    info "Nerd Font Setup"
    echo ""
    echo "Nerd Fonts include powerline symbols used by oh-my-tmux status bar."
    echo "Without a Nerd Font, symbols will display as boxes."
    echo ""

    # WSL detection
    if grep -qi microsoft /proc/version 2>/dev/null; then
        warn "WSL detected: Fonts must be installed on Windows."
        echo ""
        echo "Options:"
        echo "  1) Download font to Windows Downloads folder"
        echo "  2) Skip font installation"
        echo ""
        read -p "Select option [1-2]: " wsl_choice
        case "$wsl_choice" in
            1)
                # Get Windows username and Downloads path
                local win_user
                win_user=$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
                local downloads_path="/mnt/c/Users/${win_user}/Downloads"
                if [[ ! -d "$downloads_path" ]]; then
                    warn "Could not find Windows Downloads folder, using current directory"
                    downloads_path="."
                fi

                echo ""
                echo "Select a Nerd Font to download:"
                echo "  1) Hack Nerd Font        - Clean, monospace (popular)"
                echo "  2) JetBrains Mono        - Modern, readable"
                echo "  3) Fira Code Nerd Font   - Ligatures, popular"
                echo "  4) Meslo LG Nerd Font    - Apple-style"
                echo "  5) CaskaydiaCove         - Cascadia Code (Microsoft, best Windows compat)"
                echo ""
                read -p "Select font [1-5]: " font_choice
                local font_zip=""
                case "$font_choice" in
                    1) font_zip="Hack" ;;
                    2) font_zip="JetBrainsMono" ;;
                    3) font_zip="FiraCode" ;;
                    4) font_zip="Meslo" ;;
                    5) font_zip="CascadiaCode" ;;
                    *) warn "Invalid choice."; return ;;
                esac
                local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_zip}.zip"
                info "Downloading ${font_zip}.zip to $downloads_path..."
                curl -fsSL "$url" -o "${downloads_path}/${font_zip}.zip" || { error "Download failed"; return 1; }
                info "Downloaded: ${downloads_path}/${font_zip}.zip"
                echo ""
                echo "Next steps:"
                echo "  1. Open Downloads folder in Windows Explorer"
                echo "  2. Extract ${font_zip}.zip"
                echo "  3. Select all .ttf files -> Right-click -> Install"
                echo "  4. Configure your terminal to use the 'Mono' variant of the font"
                echo "     (e.g., 'Hack Nerd Font Mono' not 'Hack Nerd Font')"
                echo ""
                echo "     Windows Terminal:"
                echo "       Settings -> Profile -> Appearance -> Font face"
                echo ""
                echo "     Cmder/ConEmu:"
                echo "       Settings (Win+Alt+P) -> Main -> Font -> Main console font"
                echo ""
                prompt_separator_style "true"
                ;;
            *)
                info "Skipping font installation."
                prompt_separator_style "false"
                ;;
        esac
        return
    fi

    # Check for existing Nerd Fonts
    local existing_fonts
    existing_fonts=$(list_installed_nerd_fonts)
    if [[ -n "$existing_fonts" ]]; then
        info "Found installed Nerd Font(s):"
        echo "$existing_fonts" | sed 's/^/  /'
        echo ""
        read -p "Install another font? [y/N]: " install_another
        if [[ ! "$install_another" =~ ^[Yy]$ ]]; then
            info "Skipping font installation."
            echo ""
            echo "Remember to configure your terminal to use the 'Mono' variant of the Nerd Font!"
            echo "(e.g., 'Hack Nerd Font Mono' not 'Hack Nerd Font')"
            prompt_separator_style "true"
            return
        fi
    fi

    echo ""
    echo "Select a Nerd Font to install:"
    echo "  1) Hack Nerd Font        - Clean, monospace (popular)"
    echo "  2) JetBrains Mono        - Modern, readable"
    echo "  3) Fira Code Nerd Font   - Ligatures, popular"
    echo "  4) Meslo LG Nerd Font    - Apple-style"
    echo "  5) Source Code Pro       - Adobe's coding font"
    echo "  6) CaskaydiaCove         - Cascadia Code (Microsoft, best Windows compat)"
    echo "  7) Skip"
    echo ""
    read -p "Select option [1-7]: " choice

    local font_cask=""
    local font_zip=""
    local font_name=""
    case "$choice" in
        1)
            font_cask="font-hack-nerd-font"
            font_zip="Hack"
            font_name="Hack Nerd Font"
            ;;
        2)
            font_cask="font-jetbrains-mono-nerd-font"
            font_zip="JetBrainsMono"
            font_name="JetBrains Mono Nerd Font"
            ;;
        3)
            font_cask="font-fira-code-nerd-font"
            font_zip="FiraCode"
            font_name="Fira Code Nerd Font"
            ;;
        4)
            font_cask="font-meslo-lg-nerd-font"
            font_zip="Meslo"
            font_name="Meslo LG Nerd Font"
            ;;
        5)
            font_cask="font-sauce-code-pro-nerd-font"
            font_zip="SourceCodePro"
            font_name="SauceCodePro Nerd Font"
            ;;
        6)
            font_cask="font-caskaydia-cove-nerd-font"
            font_zip="CascadiaCode"
            font_name="CaskaydiaCove Nerd Font"
            ;;
        7)
            info "Skipping font installation."
            prompt_separator_style "false"
            return
            ;;
        *)
            warn "Invalid choice. Skipping font installation."
            prompt_separator_style "false"
            return
            ;;
    esac

    if [[ -n "$font_name" ]]; then
        if is_macos && check_cmd brew; then
            info "Installing $font_name via Homebrew..."
            if brew install --cask "$font_cask"; then
                info "$font_name installed successfully!"
            else
                error "Failed to install $font_name"
                return
            fi
        elif is_linux; then
            download_nerd_font_linux "$font_name" "$font_zip" || return
        else
            warn "No supported installation method found."
            warn "Download manually from: https://www.nerdfonts.com/font-downloads"
            return
        fi

        echo ""
        echo "Next step: Configure your terminal to use the 'Mono' variant of '$font_name'"
        echo "           (e.g., 'Hack Nerd Font Mono' not 'Hack Nerd Font')"
        echo ""
        echo "Terminal configuration:"
        if is_macos; then
            echo "  iTerm2:       Preferences > Profiles > Text > Font"
            echo "  Terminal.app: Preferences > Profiles > Font > Change"
        fi
        echo "  Alacritty:    ~/.config/alacritty/alacritty.yml (font.normal.family)"
        echo "  Kitty:        ~/.config/kitty/kitty.conf (font_family)"
        echo "  VS Code:      Settings > Terminal > Font Family"

        prompt_separator_style "true"
    fi
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

    echo "Fzf:"
    if check_cmd fzf; then
        echo "  ✓ fzf $(fzf --version | head -1)"
    else
        echo "  ✗ fzf (required for tmux-fzf plugin)"
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

    echo "Nerd Fonts (for powerline symbols):"
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "  WSL detected - check Windows fonts"
        echo "  Run: ./install-dependencies.sh fonts"
    else
        local nerd_fonts
        nerd_fonts=$(list_installed_nerd_fonts)
        if [[ -n "$nerd_fonts" ]]; then
            echo "$nerd_fonts" | while read -r font; do
                echo "  ✓ $font"
            done
        else
            echo "  ✗ No Nerd Font found (symbols will show as boxes)"
            echo "    Run: ./install-dependencies.sh fonts"
        fi
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
        fzf)
            install_fzf
            ;;
        fonts|font|nerd-font)
            install_nerd_font
            ;;
        status|check)
            check_status
            ;;
        all)
            install_tmux
            echo ""
            install_fzf
            echo ""
            install_tpm
            echo ""
            install_nerd_font
            echo ""
            check_status
            ;;
        *)
            echo "Usage: $0 [tmux|fzf|tpm|fonts|status|all]"
            echo ""
            echo "Options:"
            echo "  tmux     Install tmux"
            echo "  fzf      Install fzf (for tmux-fzf plugin)"
            echo "  tpm      Install tmux plugin manager"
            echo "  fonts    Install a Nerd Font (for powerline symbols)"
            echo "  status   Check installation status"
            echo "  all      Install all dependencies (default)"
            exit 1
            ;;
    esac

    info "Done!"
}

main "$@"
