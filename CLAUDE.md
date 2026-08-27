# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository for macOS. Manages configuration for three main tools: Neovim, tmux, and zsh. No build system or tests — changes are validated by reloading the relevant tool.

## Repository Structure

- `.zshrc` — Zsh config (Oh My Zsh, robbyrussell theme, homebrew, nvm)
- `.tmux.conf` — Tmux config (prefix is `C-a`, uses TPM + tmux-powerline)
- `nvim/` — Full Neovim config (based on kickstart.nvim, uses lazy.nvim)
- `bin/` — Shell scripts for tmux popup pickers (require fzf)
- `tmux-powerline/` — Tmux-powerline theme and segment config

## Neovim Config Architecture

Entry point is `nvim/init.lua`. Plugin management via lazy.nvim with this layout:

- `nvim/init.lua` — Options, base settings, lazy.nvim bootstrap, plugin imports
- `nvim/lua/custom/keymaps.lua` — All non-plugin keymaps
- `nvim/lua/custom/autocmds.lua` — Autocommands (trim whitespace, auto-save on blur, auto-refresh buffers)
- `nvim/lua/custom/plugins/` — One file per plugin (loaded via `{ import = 'custom.plugins' }`)
- `nvim/lua/custom/plugins/themes/` — Colorscheme plugins (active: everforest)
- `nvim/lua/kickstart/plugins/` — Upstream kickstart plugin configs (indent_line, autopairs, neo-tree are enabled)
- `nvim/lua/smart-replace/` — Custom local plugin for case-aware find/replace
- `nvim/lua/server-terminal.lua` — Terminal management module for running server/component instances
- `nvim/after/ftplugin/` — Filetype-specific overrides (ruby, markdown, text, tml)

Leader key is `<Space>`. Tabs are 2 spaces. Lua formatting uses stylua (see `nvim/.stylua.toml`).

## Key Conventions

- Prefer a plugin's built-in functionality over a custom implementation. Before adding bespoke keymaps, autocmds, or Lua wrappers to change how a plugin behaves, read that plugin's own docs and source (installed under `~/.local/share/nvim/lazy/<plugin>/`, plus `:help <plugin>`) for an existing option, command, or default mapping that already does it. Surface what the plugin offers and suggest using it before writing anything custom.
  - Example: for a change to Neogit interaction, check Neogit's setup options, its built-in commands, and its existing popup/section mappings before defining a new keybinding or extension.
- If no installed plugin covers it, look for an existing community plugin that does (search the web, awesome-neovim, GitHub) before writing a custom solution. Present the candidates — with what each does and how actively maintained it is — and let the user pick; don't install one unasked.
- Write a custom implementation only when neither an installed plugin nor a community plugin fits, and say why when proposing it.
- New Neovim plugins go in `nvim/lua/custom/plugins/` as individual `.lua` files returning a lazy.nvim spec
- The zshrc sources `~/.zshrc.local` at the end for machine-specific config
- Tmux prefix is `C-a` (not default `C-b`); pane navigation uses hjkl
- Tmux project picker (`C-a f`) browses `~/wsgr/neuron` subdirectories via fzf
- Tmux window picker (`C-a w`) fuzzy-finds open windows

## Applying Changes

- **Neovim**: Restart nvim or `:Lazy` to manage plugins
- **Tmux**: `C-a R` reloads `.tmux.conf`
- **Zsh**: `source ~/.zshrc` or use the `zrc` alias
