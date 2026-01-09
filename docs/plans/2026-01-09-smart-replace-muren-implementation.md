# Smart Replace with Muren.nvim Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build smart case-aware replace using muren.nvim for the multi-line UI.

**Architecture:** Fork muren.nvim to add `opts.replacements` support, then build a wrapper that generates case variants and opens muren pre-populated. Reuse case detection logic from original smart-replace plan.

**Tech Stack:** Lua, Neovim API, nui.nvim, muren.nvim (forked)

**Design Doc:** `docs/plans/2026-01-09-smart-replace-muren-design.md`

---

## Part 1: Muren.nvim Fork

### Task 1: Fork and clone muren.nvim

**Files:**
- Clone: `~/projects/muren.nvim` (or your preferred location)

**Step 1: Fork on GitHub**

Go to https://github.com/AckslD/muren.nvim and click "Fork" to create `SHDavies/muren.nvim`.

**Step 2: Clone your fork locally**

Run:
```bash
git clone git@github.com:SHDavies/muren.nvim.git ~/projects/muren.nvim
```

**Step 3: Verify clone**

Run: `ls ~/projects/muren.nvim/lua/muren/`
Expected: `init.lua`, `ui.lua`, `search.lua`, and other files

**Step 4: No commit needed** (just setup)

---

### Task 2: Add opts.replacements support to muren

**Files:**
- Modify: `~/projects/muren.nvim/lua/muren/ui.lua`

**Step 1: Locate the replacements buffer initialization**

Run:
```bash
grep -n "last_lines.replacements" ~/projects/muren.nvim/lua/muren/ui.lua
```

Expected: Line showing `vim.api.nvim_buf_set_lines(bufs.replacements, 0, -1, true, last_lines.replacements or {})`

**Step 2: Update to support opts.replacements**

Find this block (around the patterns/replacements buffer initialization):

```lua
vim.api.nvim_buf_set_lines(bufs.replacements, 0, -1, true, last_lines.replacements or {})
```

Replace with:

```lua
if opts.replacements then
  vim.api.nvim_buf_set_lines(bufs.replacements, 0, -1, true, opts.replacements)
elseif not opts.fresh then
  vim.api.nvim_buf_set_lines(bufs.replacements, 0, -1, true, last_lines.replacements or {})
end
```

**Step 3: Verify the change mirrors opts.patterns logic**

The patterns logic should look like:
```lua
if opts.patterns then
  vim.api.nvim_buf_set_lines(bufs.patterns, 0, -1, true, opts.patterns)
elseif not opts.fresh then
  vim.api.nvim_buf_set_lines(bufs.patterns, 0, -1, true, last_lines.patterns or {})
end
```

Your replacements logic should follow the same structure.

**Step 4: Commit**

```bash
cd ~/projects/muren.nvim
git add lua/muren/ui.lua
git commit -m "feat: add opts.replacements support to open_ui

Mirrors existing opts.patterns behavior, allowing programmatic
pre-population of the replacements buffer.

Enables integrations to open muren with both patterns and
replacements pre-filled."
```

---

### Task 3: Test muren fork locally

**Files:**
- Modify: `nvim/lua/custom/plugins/smart-replace.lua` (temporary test)

**Step 1: Create temporary test spec pointing to local fork**

Create `nvim/lua/custom/plugins/smart-replace.lua`:

```lua
return {
  dir = '~/projects/muren.nvim',
  name = 'muren-fork',
  opts = {},
  keys = {
    {
      '<leader>mt',
      function()
        require('muren.api').open_ui({
          patterns = { 'foo', 'bar' },
          replacements = { 'baz', 'qux' },
        })
      end,
      desc = '[M]uren [T]est',
    },
  },
}
```

**Step 2: Reload neovim and test**

Run:
1. Open neovim
2. Create a test file with content: `foo bar foo`
3. Press `<leader>mt`

Expected: Muren opens with:
- Left pane (patterns): `foo` and `bar` on separate lines
- Right pane (replacements): `baz` and `qux` on separate lines

**Step 3: Verify replacement works**

Press `<CR>` (or however muren applies replacements)
Expected: `foo` becomes `baz`, `bar` becomes `qux`

**Step 4: No commit needed** (this was a manual test)

---

### Task 4: Push fork and create upstream PR

**Step 1: Push to your fork**

```bash
cd ~/projects/muren.nvim
git push origin main
```

**Step 2: Create PR to upstream**

Go to https://github.com/SHDavies/muren.nvim and click "Contribute" → "Open pull request"

Title: `feat: add opts.replacements support to open_ui`

Body:
```markdown
## Summary
Adds `opts.replacements` parameter to `open_ui()`, mirroring existing `opts.patterns` behavior.

## Motivation
Enables programmatic pre-population of both patterns and replacements buffers, useful for integrations that want to open muren with specific search/replace pairs already filled in.

## Changes
- `lua/muren/ui.lua`: Add conditional logic for `opts.replacements` matching the `opts.patterns` pattern

## Testing
Tested locally by calling:
```lua
require('muren.api').open_ui({
  patterns = { 'foo', 'bar' },
  replacements = { 'baz', 'qux' },
})
```
Both buffers populate correctly and replacements work as expected.
```

**Step 3: No commit needed** (PR is external action)

---

## Part 2: Smart-Replace Plugin

### Task 5: Create plugin skeleton with muren dependency

**Files:**
- Create: `nvim/lua/smart-replace/init.lua`
- Modify: `nvim/lua/custom/plugins/smart-replace.lua`

**Step 1: Create main module skeleton**

Create `nvim/lua/smart-replace/init.lua`:

```lua
local M = {}

function M.setup(opts)
  opts = opts or {}
  M.opts = opts
end

return M
```

**Step 2: Update lazy.nvim spec**

Replace `nvim/lua/custom/plugins/smart-replace.lua`:

```lua
return {
  dir = vim.fn.stdpath('config') .. '/lua/smart-replace',
  name = 'smart-replace',
  dependencies = {
    'MunifTanjim/nui.nvim',
    {
      'SHDavies/muren.nvim',
      opts = {},
    },
  },
  config = function()
    require('smart-replace').setup()
  end,
  keys = {
    {
      '<leader>rw',
      function()
        require('smart-replace').replace_word()
      end,
      mode = { 'n', 'v' },
      desc = '[R]eplace [W]ord',
    },
    {
      '<leader>rc',
      function()
        require('smart-replace').replace_casing()
      end,
      mode = { 'n', 'v' },
      desc = '[R]eplace [C]asing',
    },
  },
}
```

**Step 3: Verify plugin loads**

Run: Open neovim, run `:lua require('smart-replace')`
Expected: No errors

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/init.lua nvim/lua/custom/plugins/smart-replace.lua
git commit -m "feat(smart-replace): add plugin skeleton with muren dependency"
```

---

### Task 6: Add source text detection

**Files:**
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Add helper function**

Add to `nvim/lua/smart-replace/init.lua` before `M.setup`:

```lua
local function get_source_text()
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\22' then
    -- Visual mode: get selected text
    vim.cmd('noau normal! "vy')
    local text = vim.fn.getreg('v')
    vim.fn.setreg('v', {})
    return text
  else
    -- Normal mode: get word under cursor
    return vim.fn.expand('<cword>')
  end
end
```

**Step 2: Add stub functions**

Add before `return M`:

```lua
function M.replace_word()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end
  vim.notify('replace_word: ' .. source)
end

function M.replace_casing()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end
  vim.notify('replace_casing: ' .. source)
end
```

**Step 3: Verify detection works**

Run:
1. Open neovim, place cursor on a word, press `<leader>rw`
2. Select text in visual mode, press `<leader>rc`

Expected: Notifications show the detected text

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): add source text detection"
```

---

### Task 7: Create nui.Input prompt

**Files:**
- Create: `nvim/lua/smart-replace/ui.lua`

**Step 1: Create UI module**

Create `nvim/lua/smart-replace/ui.lua`:

```lua
local Input = require('nui.input')

local M = {}

function M.prompt_replacement(source, on_submit)
  local input = Input({
    position = '50%',
    size = { width = 40 },
    border = {
      style = 'rounded',
      text = {
        top = ' Replace ' .. source .. ' ',
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = 'Normal:Normal,FloatBorder:Normal',
    },
  }, {
    prompt = '> ',
    default_value = source,
    on_submit = function(value)
      if value and value ~= '' then
        on_submit(value)
      end
    end,
  })

  input:mount()

  input:map('n', '<Esc>', function()
    input:unmount()
  end, { noremap = true })

  input:map('i', '<C-c>', function()
    input:unmount()
  end, { noremap = true })
end

return M
```

**Step 2: Verify input works**

Run: `:lua require('smart-replace.ui').prompt_replacement('test', function(v) print(v) end)`
Expected: Input appears, submitting prints the value

**Step 3: Commit**

```bash
git add nvim/lua/smart-replace/ui.lua
git commit -m "feat(smart-replace): add nui.Input prompt"
```

---

### Task 8: Implement simple replace_word

**Files:**
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Add escape and replace functions**

Add after `get_source_text` function:

```lua
local function escape_pattern(text)
  return text:gsub('\\', '\\\\'):gsub('/', '\\/')
end

local function do_replace(source, replacement)
  local escaped_source = escape_pattern(source)
  local escaped_replacement = replacement:gsub('/', '\\/')

  -- Count matches first
  local count = 0
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local _, matches = line:gsub(vim.pesc(source), '')
    count = count + matches
  end

  if count == 0 then
    vim.notify('No matches found for "' .. source .. '"', vim.log.levels.WARN)
    return
  end

  vim.cmd(':%s/\\V' .. escaped_source .. '/' .. escaped_replacement .. '/g')
  vim.notify('Replaced ' .. count .. ' occurrence' .. (count == 1 and '' or 's'))
end
```

**Step 2: Update replace_word to use prompt and replace**

Replace `M.replace_word`:

```lua
function M.replace_word()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ui = require('smart-replace.ui')
  ui.prompt_replacement(source, function(replacement)
    do_replace(source, replacement)
  end)
end
```

**Step 3: Verify replace_word works**

Run:
1. Create file with: `foo bar foo baz foo`
2. Place cursor on `foo`, press `<leader>rw`
3. Type `qux`, press Enter

Expected: All `foo` replaced with `qux`, notification shows count

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): implement simple replace_word"
```

---

### Task 9: Create case detection module

**Files:**
- Create: `nvim/lua/smart-replace/case.lua`

**Step 1: Create case module with detection and splitting**

Create `nvim/lua/smart-replace/case.lua`:

```lua
local M = {}

function M.detect_style(str)
  if str:match('^%u+$') then
    return 'SCREAMING_SNAKE'
  elseif str:match('^%l+$') then
    return 'lowercase'
  elseif str:match('_') then
    if str:match('^%u[%u_]*%u$') or str:match('^%u+_') then
      return 'SCREAMING_SNAKE'
    else
      return 'snake_case'
    end
  elseif str:match('%-') then
    return 'kebab-case'
  elseif str:match(' ') then
    if str:match('^%u') and str:match(' %u') then
      return 'Title Case'
    else
      return 'lowercase'
    end
  elseif str:match('^%u') then
    return 'PascalCase'
  elseif str:match('%u') then
    return 'camelCase'
  else
    return 'lowercase'
  end
end

function M.split_words(str)
  local style = M.detect_style(str)
  local words = {}
  local acronyms = {}

  if style == 'snake_case' or style == 'SCREAMING_SNAKE' then
    for word in str:gmatch('[^_]+') do
      table.insert(words, word:lower())
    end
  elseif style == 'kebab-case' then
    for word in str:gmatch('[^%-]+') do
      table.insert(words, word:lower())
    end
  elseif style == 'Title Case' or style == 'lowercase' then
    for word in str:gmatch('%S+') do
      table.insert(words, word:lower())
    end
  elseif style == 'PascalCase' or style == 'camelCase' then
    local i = 1
    local len = #str
    local word_idx = 0
    while i <= len do
      local char = str:sub(i, i)
      if char:match('%u') then
        word_idx = word_idx + 1
        local j = i + 1
        while j <= len and str:sub(j, j):match('%u') do
          j = j + 1
        end
        if j > i + 1 and j <= len and str:sub(j, j):match('%l') then
          table.insert(words, str:sub(i, j - 2):lower())
          acronyms[word_idx] = true
          i = j - 1
        elseif j > i + 1 then
          table.insert(words, str:sub(i, j - 1):lower())
          acronyms[word_idx] = true
          i = j
        else
          local k = j
          while k <= len and str:sub(k, k):match('%l') do
            k = k + 1
          end
          table.insert(words, str:sub(i, k - 1):lower())
          i = k
        end
      else
        word_idx = word_idx + 1
        local j = i
        while j <= len and str:sub(j, j):match('%l') do
          j = j + 1
        end
        if j > i then
          table.insert(words, str:sub(i, j - 1):lower())
        end
        i = j
      end
    end
  end

  return { words = words, acronyms = acronyms }
end

return M
```

**Step 2: Test detection**

Run:
```
:lua print(vim.inspect(require('smart-replace.case').split_words('someValue')))
:lua print(vim.inspect(require('smart-replace.case').split_words('HTTPMethod')))
:lua print(vim.inspect(require('smart-replace.case').split_words('parseJSON')))
```

Expected:
- `someValue` → `{ words = {"some", "value"}, acronyms = {} }`
- `HTTPMethod` → `{ words = {"http", "method"}, acronyms = {[1] = true} }`
- `parseJSON` → `{ words = {"parse", "json"}, acronyms = {[2] = true} }`

**Step 3: Commit**

```bash
git add nvim/lua/smart-replace/case.lua
git commit -m "feat(smart-replace): add case detection and word splitting"
```

---

### Task 10: Add case conversion functions

**Files:**
- Modify: `nvim/lua/smart-replace/case.lua`

**Step 1: Add conversion functions**

Add to `nvim/lua/smart-replace/case.lua` before `return M`:

```lua
function M.to_camel_case(words, acronyms)
  acronyms = acronyms or {}
  local result = {}
  for i, word in ipairs(words) do
    if i == 1 then
      table.insert(result, word:lower())
    else
      if acronyms[i] then
        table.insert(result, word:upper())
      else
        table.insert(result, word:sub(1, 1):upper() .. word:sub(2):lower())
      end
    end
  end
  return table.concat(result)
end

function M.to_pascal_case(words, acronyms)
  acronyms = acronyms or {}
  local result = {}
  for i, word in ipairs(words) do
    if acronyms[i] then
      table.insert(result, word:upper())
    else
      table.insert(result, word:sub(1, 1):upper() .. word:sub(2):lower())
    end
  end
  return table.concat(result)
end

function M.to_snake_case(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:lower())
  end
  return table.concat(result, '_')
end

function M.to_screaming_snake(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:upper())
  end
  return table.concat(result, '_')
end

function M.to_kebab_case(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:lower())
  end
  return table.concat(result, '-')
end

function M.to_title_case(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:sub(1, 1):upper() .. word:sub(2):lower())
  end
  return table.concat(result, ' ')
end

function M.to_lowercase(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:lower())
  end
  return table.concat(result, ' ')
end

function M.generate_variants(words, acronyms)
  return {
    { style = 'camelCase', value = M.to_camel_case(words, acronyms) },
    { style = 'PascalCase', value = M.to_pascal_case(words, acronyms) },
    { style = 'snake_case', value = M.to_snake_case(words) },
    { style = 'SCREAMING_SNAKE', value = M.to_screaming_snake(words) },
    { style = 'kebab-case', value = M.to_kebab_case(words) },
    { style = 'Title Case', value = M.to_title_case(words) },
    { style = 'lowercase', value = M.to_lowercase(words) },
  }
end
```

**Step 2: Test conversions**

Run:
```
:lua local c = require('smart-replace.case'); local p = c.split_words('someValue'); print(vim.inspect(c.generate_variants(p.words, p.acronyms)))
```

Expected: Table with 7 variants (someValue, SomeValue, some_value, etc.)

**Step 3: Commit**

```bash
git add nvim/lua/smart-replace/case.lua
git commit -m "feat(smart-replace): add case conversion functions"
```

---

### Task 11: Integrate replace_casing with muren

**Files:**
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Update replace_casing to open muren**

Replace `M.replace_casing` in `nvim/lua/smart-replace/init.lua`:

```lua
function M.replace_casing()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ui = require('smart-replace.ui')
  local case = require('smart-replace.case')

  ui.prompt_replacement(source, function(replacement)
    local source_parsed = case.split_words(source)
    local replacement_parsed = case.split_words(replacement)

    local source_variants = case.generate_variants(source_parsed.words, source_parsed.acronyms)
    local replacement_variants = case.generate_variants(replacement_parsed.words, replacement_parsed.acronyms)

    local patterns = {}
    local replacements = {}
    for i, sv in ipairs(source_variants) do
      table.insert(patterns, sv.value)
      table.insert(replacements, replacement_variants[i].value)
    end

    require('muren.api').open_ui({
      patterns = patterns,
      replacements = replacements,
    })
  end)
end
```

**Step 2: Test full flow**

Run:
1. Create file with:
   ```
   const someValue = 1;
   const SOME_VALUE = 2;
   const some_value = 3;
   const SomeValue = 4;
   ```
2. Place cursor on `someValue`, press `<leader>rc`
3. Type `otherThing`, press Enter

Expected: Muren opens with 7 patterns on left, 7 replacements on right:
- someValue → otherThing
- SomeValue → OtherThing
- some_value → other_thing
- etc.

**Step 3: Execute replacement in muren and verify**

Press Enter in muren to apply
Expected: All matching variants replaced

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): integrate replace_casing with muren"
```

---

### Task 12: Test acronym handling

**Files:**
- None (manual testing)

**Step 1: Test acronym preservation**

Run:
1. Create file with:
   ```
   parseJSON();
   ParseJSON();
   parse_json();
   PARSE_JSON();
   ```
2. Place cursor on `parseJSON`, press `<leader>rc`
3. Type `formatXML`, press Enter

Expected popup shows:
- parseJSON → formatXML
- ParseJSON → FormatXML
- parse_json → format_xml
- PARSE_JSON → FORMAT_XML
- etc.

**Step 2: Verify acronym in source is detected**

Run:
1. Create file with `HTTPMethod`
2. Press `<leader>rc` on it
3. Type `RPCCall`

Expected: `HTTPMethod → RPCCall`, `httpMethod → rpcCall`, etc.

**Step 3: No commit needed** (manual testing)

---

## Summary

After completing all tasks:

| Keybinding | Function | Description |
|------------|----------|-------------|
| `<leader>rw` | `replace_word()` | Simple exact replace via input |
| `<leader>rc` | `replace_casing()` | Smart case-aware replace via muren |

**Files created:**
- `nvim/lua/custom/plugins/smart-replace.lua` - lazy.nvim spec
- `nvim/lua/smart-replace/init.lua` - main module
- `nvim/lua/smart-replace/ui.lua` - nui.Input prompt
- `nvim/lua/smart-replace/case.lua` - case detection/conversion

**External:**
- `SHDavies/muren.nvim` - fork with `opts.replacements` support
- PR submitted to `AckslD/muren.nvim`

**Follow-up tasks (not in this plan):**
1. Scope toggle (file/project) using muren's directory support
2. Customizable keybindings via setup options
3. Update dependency when/if upstream PR is merged
