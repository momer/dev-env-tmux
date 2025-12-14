# Tmux Development Environment Makefile
#
# Usage:
#   make install          - Full setup (tmux config + dependencies)
#   make setup            - Install tmux config only
#   make deps             - Install tmux and tpm
#   make help             - Show all targets

.PHONY: help install setup setup-symlink setup-minimal update-config plugins update update-oh-my-tmux deps deps-tmux deps-tpm status clean

# Default target
help:
	@echo "Tmux Development Environment (Oh My Tmux)"
	@echo ""
	@echo "Setup targets:"
	@echo "  make install          Full setup: tmux config + dependencies"
	@echo "  make setup            Install tmux config (copy files)"
	@echo "  make setup-symlink    Install tmux config (symlink files)"
	@echo "  make setup-minimal    Install tmux config without plugins"
	@echo "  make update-config    Update config only (no backup prompt)"
	@echo "  make plugins          Install/update tmux plugins via tpm"
	@echo "  make update           Update tmux plugins"
	@echo "  make update-oh-my-tmux  Update oh-my-tmux to latest"
	@echo ""
	@echo "Dependency targets:"
	@echo "  make deps             Install all dependencies (tmux + tpm)"
	@echo "  make deps-tmux        Install tmux"
	@echo "  make deps-tpm         Install tmux plugin manager"
	@echo ""
	@echo "Other targets:"
	@echo "  make status           Check installation status"
	@echo "  make clean            Remove tmux config (keeps backups)"

# Full installation
install: setup
	@$(MAKE) deps
	@echo ""
	@echo "Installation complete!"
	@echo "Run 'make status' to verify installation."

# Setup tmux configuration (copy)
setup:
	./setup.sh

# Setup tmux configuration (symlink)
setup-symlink:
	./setup.sh --symlink

# Setup tmux configuration without plugins
setup-minimal:
	./setup.sh --no-plugins

# Update config only (direct copy, no full setup)
update-config:
	@cp tmux.conf.local ~/.tmux.conf.local
	@echo "Updated ~/.tmux.conf.local"
	@echo "Run 'tmux source-file ~/.tmux.conf' or prefix + r to reload"

# Install/update tmux plugins via tpm
plugins:
	@if [ -d ~/.tmux/plugins/tpm ]; then \
		~/.tmux/plugins/tpm/bin/install_plugins; \
	else \
		echo "tpm not installed. Run 'make deps-tpm' first."; \
	fi

# Update tmux plugins
update:
	@if [ -d ~/.tmux/plugins/tpm ]; then \
		~/.tmux/plugins/tpm/bin/update_plugins all; \
	else \
		echo "tpm not installed. Run 'make deps-tpm' first."; \
	fi

# Update oh-my-tmux
update-oh-my-tmux:
	@if [ -d ~/.tmux/oh-my-tmux ]; then \
		cd ~/.tmux/oh-my-tmux && git pull; \
	else \
		echo "oh-my-tmux not installed. Run 'make setup' first."; \
	fi

# Install all dependencies
deps: deps-tmux deps-tpm
	@$(MAKE) status

# Tmux
deps-tmux:
	./install-dependencies.sh tmux

# Tmux Plugin Manager
deps-tpm:
	./install-dependencies.sh tpm

# Check status
status:
	./install-dependencies.sh status

# Clean up (remove installed config, keeps backups)
clean:
	@echo "Removing tmux configuration..."
	@[ -L ~/.tmux.conf ] && rm -- ~/.tmux.conf || true
	@[ -f ~/.tmux.conf.local ] && rm -- ~/.tmux.conf.local || true
	@[ -L ~/.tmux.conf.local ] && rm -- ~/.tmux.conf.local || true
	@echo "Removed ~/.tmux.conf and ~/.tmux.conf.local"
	@echo "Note: ~/.tmux (plugins, oh-my-tmux) preserved"
	@echo "Note: Backup files (*.backup.*) preserved"
