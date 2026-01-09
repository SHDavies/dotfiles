# Smart Replace - Neovim Plugin Design

A neovim plugin for case-aware find-and-replace within a file, using nui.nvim for UI.

## Overview

Replace all occurrences of a word with smart case transformations. Supports multiple casing styles: `camelCase`, `PascalCase`, `snake_case`, `SCREAMING_SNAKE_CASE`, `kebab-case`, `Title Case`, and `lowercase`.

## Phased Implementation

### Phase 1 - Basic Replace

**Keybinding:** `<leader>rw` (Replace Word)

**Flow:**
1. In normal mode: get word under cursor via `vim.fn.expand('<cword>')`
2. In visual mode: get selected text
3. Open `nui.Input` with border text: `Replace <source-word>`
4. On submit: run `:%s/\V<source>/<replacement>/g` (using `\V` for literal matching)
5. Report result via `vim.notify()`: `"Replaced 4 occurrences"` (handled by noice)

**nui.Input config:**
- Centered floating window
- Border text: `Replace <source-word>`
- Pre-populated with source word (for easy modification)
- `<Esc>` or `<C-c>` to cancel
- `<CR>` to confirm

### Phase 1.5 - Multi-line Editable Popup

**Keybinding:** `<leader>rc` (Replace Casing)

**Flow:**
1. Get word under cursor / visual selection (same as Phase 1)
2. Open `nui.Input` for replacement text (border: `Replace <source-word>`)
3. On submit: open `nui.Popup` with initial line: `sourceWord -> replacementWord`
4. User can edit, add, or delete lines (standard vim editing)
5. On save: parse each line, run replacements as single undo operation, close popup
6. On quit without save: cancel, no replacements

**Popup format:**
```
someValue -> otherValue
_______________________________
[file] | <C-s> save | <Esc> cancel
```

- Each line: `source -> replacement` (whitespace around `->` trimmed)
- Empty lines and lines without `->` are ignored
- Footer shows scope (readonly "file" for now) and keybinding hints

**Keybindings in popup:**

| Command | Behavior |
|---------|----------|
| `:w` or `<C-s>` | Execute replacements and close |
| `:wq` | Same as `:w` (execute and close) |
| `:q` | Cancel and close (no replacements) |
| `:q!` | Same as `:q` (cancel) |
| `<Esc>` | Same as `:q` (cancel) |

**Undo behavior:** All replacements grouped into single undo operation.

**Result reporting:** Use `vim.notify()` for replacement count (handled by noice).

### Phase 2 - Smart Case-Aware Replace

**Keybinding:** Same `<leader>rc` - now enhanced with smart case detection

**Flow changes from Phase 1.5:**
1. Get word under cursor / visual selection
2. Parse into word list: `someValue` -> `["some", "value"]`
3. Open `nui.Input` for replacement text (border: `Replace <source-word>`)
4. Parse replacement into word list: `otherThing` -> `["other", "thing"]`
5. Generate all case variant pairs and populate popup

**Case detection logic:**

```
Input: "someValue"
1. Detect style: camelCase
2. Split into words: ["some", "value"]
3. Generate all variants of replacement words ["other", "thing"]:
   - camelCase:       otherThing
   - PascalCase:      OtherThing
   - snake_case:      other_thing
   - SCREAMING_SNAKE: OTHER_THING
   - kebab-case:      other-thing
   - Title Case:      Other Thing
   - lowercase:       other thing
```

**Popup content (auto-generated):**
```
someValue -> otherThing
SomeValue -> OtherThing
some_value -> other_thing
SOME_VALUE -> OTHER_THING
some-value -> other-thing
Some Value -> Other Thing
some value -> other thing
_______________________________
[file] | <C-s> save | <Esc> cancel
```

User can delete irrelevant lines or add custom lines before saving.

**Acronym detection:**

A run of 2+ uppercase letters is treated as an acronym. Split before the last uppercase if followed by lowercase.

| Input | Parsed words |
|-------|--------------|
| `HTTPMethod` | `["HTTP", "Method"]` |
| `parseJSON` | `["parse", "JSON"]` |
| `myXMLParser` | `["my", "XML", "Parser"]` |
| `getURLString` | `["get", "URL", "String"]` |

**Acronym output by case style:**

| Source | PascalCase | camelCase |
|--------|------------|-----------|
| `parseJSON` | `ParseJSON` | `parseJSON` |
| `ParseJSON` | `ParseJSON` | `parseJSON` |
| `HTTPMethod` | `HTTPMethod` | `httpMethod` |

Acronyms stay all-caps in PascalCase/camelCase. In snake_case/kebab-case they become lowercase.

**Visual selection handling:**

Multi-word selections (e.g., `some value`) are parsed as space-separated word lists, which then generate all case variants.

## File Structure

```
nvim/lua/custom/plugins/smart-replace.lua  -- lazy.nvim spec
nvim/lua/smart-replace/init.lua            -- main module
nvim/lua/smart-replace/ui.lua              -- nui components
nvim/lua/smart-replace/case.lua            -- case detection (Phase 2)
```

Structured for eventual extraction to standalone GitHub repo.

## Dependencies

- `nui.nvim` (already installed)

## Follow-up Tasks

1. **Scope toggle (file/project):** Add keybinding to toggle between file-wide and project-wide replacement. Update footer label accordingly.

2. **Customizable keybindings:** Allow users to configure `<leader>rw` and `<leader>rc` via setup options.

3. **Extract to standalone repo:** Once stable, move to separate GitHub repo with proper documentation and tests.

4. **Preview match count:** Show number of matches per line in the popup (e.g., `someValue -> otherValue (3 matches)`)
