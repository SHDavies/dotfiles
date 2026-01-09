# Smart Replace with Muren.nvim - Design

A smart case-aware replace feature built on top of muren.nvim.

## Overview

Instead of building a custom multi-line popup UI, leverage muren.nvim's existing dual-pane interface for batch replacements. Contribute `opts.replacements` support upstream, then build a thin wrapper that generates case variants and pre-populates muren.

## Architecture

**Components:**

```
SHDavies/muren.nvim              -- Fork with opts.replacements support
nvim/lua/smart-replace/init.lua  -- Main module
nvim/lua/smart-replace/case.lua  -- Case detection/conversion
nvim/lua/smart-replace/ui.lua    -- nui.Input prompt only
nvim/lua/custom/plugins/smart-replace.lua  -- lazy.nvim spec
```

**Keybindings:**

| Keybinding | Function | Description |
|------------|----------|-------------|
| `<leader>rw` | `replace_word()` | Simple exact replace (input → immediate replace) |
| `<leader>rc` | `replace_casing()` | Smart case replace (input → muren with variants) |

## Muren.nvim Fork Changes

**Repository:** `SHDavies/muren.nvim` (fork of `AckslD/muren.nvim`)

**File:** `lua/muren/ui.lua`

**Change:** Add `opts.replacements` support to `M.open()` function, mirroring existing `opts.patterns` behavior.

**Before:**
```lua
-- Replacements buffer (no opts support)
vim.api.nvim_buf_set_lines(bufs.replacements, 0, -1, true, last_lines.replacements or {})
```

**After:**
```lua
-- Replacements buffer (now supports opts.replacements)
if opts.replacements then
  vim.api.nvim_buf_set_lines(bufs.replacements, 0, -1, true, opts.replacements)
elseif not opts.fresh then
  vim.api.nvim_buf_set_lines(bufs.replacements, 0, -1, true, last_lines.replacements or {})
end
```

**PR:** Submit upstream to `AckslD/muren.nvim` (may be stale, use fork in meantime).

## Smart-Replace Integration

**Flow for `<leader>rc`:**

1. Get word under cursor / visual selection
2. Prompt for replacement via `nui.Input` (border: `Replace <source>`)
3. Parse source and replacement into word lists
4. Generate all 7 case variants for both
5. Open muren with `{ patterns = {...}, replacements = {...} }`
6. User edits/confirms in muren UI
7. Muren handles the actual replacement

**Case variants generated:**

- camelCase
- PascalCase
- snake_case
- SCREAMING_SNAKE_CASE
- kebab-case
- Title Case
- lowercase

**Acronym handling:**

- `HTTPMethod` → `["http", "method"]` with acronym tracking
- `parseJSON` → `["parse", "json"]` with acronym tracking
- Acronyms preserved in PascalCase/camelCase output (`ParseJSON`, not `ParseJson`)

## Code Reuse

**From original smart-replace plan (`docs/plans/2026-01-09-smart-replace-design.md`):**

| Component | Status |
|-----------|--------|
| `case.lua` - case detection, word splitting, acronym handling | Reuse entirely |
| `ui.lua` - `prompt_replacement()` | Reuse |
| `init.lua` - `replace_word()` | Reuse |
| `ui.lua` - `open_replace_popup()` | Drop (muren replaces) |
| Phase 1.5 popup logic | Drop (muren handles) |

## Dependencies

- `MunifTanjim/nui.nvim` (already installed via noice)
- `SHDavies/muren.nvim` (new - fork with `opts.replacements`)

## Follow-up Tasks

1. **Scope toggle (file/project):** Muren supports directory-wide replacement - could add toggle
2. **Customizable keybindings:** Allow users to configure via setup options
3. **Preview match count:** Muren may already show this in preview
4. **Upstream PR acceptance:** Monitor and update dependency if merged
