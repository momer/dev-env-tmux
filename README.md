# Tmux Development Environment

Tmux configuration built on [oh-my-tmux](https://github.com/gpakosz/.tmux) with tpm plugins for session persistence, fuzzy finding, and vim-style navigation.

## Quick Start

```bash
make install        # Full setup (config + dependencies)

# Or step by step
make setup          # Install config only
make deps           # Install tmux, fzf, tpm, fonts
```

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| tmux | Terminal multiplexer | `make deps-tmux` |
| fzf | Fuzzy finder | `make deps-fzf` |
| tpm | Plugin manager | `make deps-tpm` |
| Nerd Font | Powerline symbols | `make deps-fonts` |

## Plugins

| Plugin | Purpose |
|--------|---------|
| tmux-resurrect | Save/restore sessions |
| tmux-continuum | Auto-save sessions (15min) |
| tmux-yank | System clipboard |
| tmux-fzf | Fuzzy finding |
| tmux-which-key | Keybinding popup |

## Key Bindings

Prefix: `Ctrl-a`

| Binding | Action |
|---------|--------|
| `prefix + f` | Open tmux-fzf menu |
| `prefix + Space` | Open which-key menu |
| `prefix + \|` | Split horizontal |
| `prefix + -` | Split vertical |
| `prefix + x` | Kill pane (no confirm) |
| `prefix + X` | Kill window (no confirm) |
| `prefix + n/p` | Next/previous window |
| `prefix + s` | Switch window (fzf) |
| `prefix + g/G` | Join pane vertical/horizontal |
| `prefix + Q` | Save session and quit |

### Copy Mode (`prefix + [`)

| Binding | Action |
|---------|--------|
| `j/k` | Line up/down |
| `C-j/C-k` | Page down/up |
| `v` | Begin selection |
| `y` | Yank selection |

## Windows/WSL

**Use Windows Terminal** for WSL. CMDER/ConEmu has unicode rendering issues with powerline symbols and Nerd Font icons.

When installing fonts on WSL (`make deps-fonts`), files download to your Windows Downloads folder. Install by right-clicking the .ttf files and selecting "Install", then configure Windows Terminal to use the font.
