# Smart Replace Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a neovim plugin for case-aware find-and-replace with nui.nvim UI.

**Architecture:** Local plugin in `lua/smart-replace/` loaded via lazy.nvim spec. Phases: basic replace (Phase 1), multi-line popup (Phase 1.5), smart case detection (Phase 2).

**Tech Stack:** Lua, Neovim API, nui.nvim (Input, Popup)

**Design Doc:** `docs/plans/2026-01-09-smart-replace-design.md`

---

## Phase 1: Basic Replace

### Task 1: Create plugin skeleton and lazy.nvim spec

**Files:**
- Create: `nvim/lua/smart-replace/init.lua`
- Create: `nvim/lua/custom/plugins/smart-replace.lua`

**Step 1: Create the main module skeleton**

Create `nvim/lua/smart-replace/init.lua`:

```lua
local M = {}

function M.setup(opts)
  opts = opts or {}
  M.opts = opts
end

return M
```

**Step 2: Create lazy.nvim spec**

Create `nvim/lua/custom/plugins/smart-replace.lua`:

```lua
return {
  dir = vim.fn.stdpath('config') .. '/lua/smart-replace',
  name = 'smart-replace',
  dependencies = { 'MunifTanjim/nui.nvim' },
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
  },
}
```

**Step 3: Verify plugin loads**

Run: Open neovim, run `:lua require('smart-replace')`
Expected: No errors

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/init.lua nvim/lua/custom/plugins/smart-replace.lua
git commit -m "feat(smart-replace): add plugin skeleton"
```

---

### Task 2: Get word under cursor or visual selection

**Files:**
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Add helper function to get source text**

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

**Step 2: Add replace_word stub that prints source text**

Add to `nvim/lua/smart-replace/init.lua` before `return M`:

```lua
function M.replace_word()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end
  vim.notify('Source: ' .. source)
end
```

**Step 3: Verify word detection**

Run:
1. Open neovim, place cursor on a word, press `<leader>rw`
2. Select text in visual mode, press `<leader>rw`

Expected: Notification shows the word/selection

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): detect word under cursor and visual selection"
```

---

### Task 3: Create nui.Input UI component

**Files:**
- Create: `nvim/lua/smart-replace/ui.lua`
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Create UI module with input prompt**

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

  -- Close on Escape
  input:map('n', '<Esc>', function()
    input:unmount()
  end, { noremap = true })

  input:map('i', '<C-c>', function()
    input:unmount()
  end, { noremap = true })
end

return M
```

**Step 2: Update init.lua to use UI module**

Replace the `M.replace_word` function in `nvim/lua/smart-replace/init.lua`:

```lua
function M.replace_word()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ui = require('smart-replace.ui')
  ui.prompt_replacement(source, function(replacement)
    vim.notify('Replace "' .. source .. '" with "' .. replacement .. '"')
  end)
end
```

**Step 3: Verify input appears**

Run: Open neovim, place cursor on word, press `<leader>rw`
Expected: Floating input appears with border text "Replace <word>", pre-filled with word

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/ui.lua nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): add nui.Input prompt for replacement"
```

---

### Task 4: Implement search and replace

**Files:**
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Add replace function**

Add to `nvim/lua/smart-replace/init.lua` after `get_source_text`:

```lua
local function escape_pattern(text)
  -- Escape special characters for \V (very nomagic) mode
  -- Only backslash and separator need escaping
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

  -- Perform replacement
  vim.cmd(':%s/\\V' .. escaped_source .. '/' .. escaped_replacement .. '/g')
  vim.notify('Replaced ' .. count .. ' occurrence' .. (count == 1 and '' or 's'))
end
```

**Step 2: Update replace_word to call do_replace**

Update the `on_submit` callback in `M.replace_word`:

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

**Step 3: Verify replacement works**

Run:
1. Create test file with content: `foo bar foo baz foo`
2. Place cursor on `foo`, press `<leader>rw`
3. Type `qux` and press Enter

Expected: All `foo` replaced with `qux`, notification shows "Replaced 3 occurrences"

**Step 4: Verify special characters work**

Run:
1. Create test file with content: `config.value = config.value + 1`
2. Place cursor on `config.value`, press `<leader>rw`
3. Type `settings.data` and press Enter

Expected: Literal replacement (dots not treated as regex wildcards)

**Step 5: Commit**

```bash
git add nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): implement search and replace with literal matching"
```

---

## Phase 1.5: Multi-line Popup

### Task 5: Add popup keybinding to lazy spec

**Files:**
- Modify: `nvim/lua/custom/plugins/smart-replace.lua`

**Step 1: Add second keybinding**

Update `nvim/lua/custom/plugins/smart-replace.lua` keys table:

```lua
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
      desc = '[R]eplace [C]asing (popup)',
    },
  },
```

**Step 2: Add stub function**

Add to `nvim/lua/smart-replace/init.lua` before `return M`:

```lua
function M.replace_casing()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  vim.notify('replace_casing: ' .. source)
end
```

**Step 3: Verify keybinding works**

Run: Open neovim, press `<leader>rc` on a word
Expected: Notification shows "replace_casing: <word>"

**Step 4: Commit**

```bash
git add nvim/lua/custom/plugins/smart-replace.lua nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): add replace_casing keybinding stub"
```

---

### Task 6: Create popup UI component

**Files:**
- Modify: `nvim/lua/smart-replace/ui.lua`

**Step 1: Add popup function**

Add to `nvim/lua/smart-replace/ui.lua` before `return M`:

```lua
local Popup = require('nui.popup')
local event = require('nui.utils.autocmd').event

function M.open_replace_popup(initial_content, on_save)
  local popup = Popup({
    position = '50%',
    size = {
      width = 60,
      height = 10,
    },
    enter = true,
    focusable = true,
    border = {
      style = 'rounded',
      text = {
        top = ' Replace Mappings ',
        top_align = 'center',
        bottom = ' [file] | <C-s> save | <Esc> cancel ',
        bottom_align = 'center',
      },
    },
    buf_options = {
      modifiable = true,
      readonly = false,
    },
    win_options = {
      winhighlight = 'Normal:Normal,FloatBorder:Normal',
    },
  })

  popup:mount()

  -- Set initial content
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, vim.split(initial_content, '\n'))

  -- Helper to get buffer content and close
  local function save_and_close()
    local lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
    popup:unmount()
    on_save(lines)
  end

  local function cancel()
    popup:unmount()
  end

  -- Keymaps
  popup:map('n', '<C-s>', save_and_close, { noremap = true })
  popup:map('n', '<Esc>', cancel, { noremap = true })

  -- Handle :w, :wq, :q, :q!
  vim.api.nvim_buf_set_option(popup.bufnr, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_name(popup.bufnr, 'smart-replace://mappings')

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = popup.bufnr,
    callback = function()
      save_and_close()
    end,
  })

  -- Handle quit commands
  popup:on(event.BufLeave, function()
    -- Only unmount if still mounted (not already saved)
    if popup._.mounted then
      popup:unmount()
    end
  end)
end
```

**Step 2: Verify popup renders**

Add temporary test to `M.replace_casing` in `init.lua`:

```lua
function M.replace_casing()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ui = require('smart-replace.ui')
  ui.open_replace_popup(source .. ' -> ', function(lines)
    vim.notify('Lines: ' .. vim.inspect(lines))
  end)
end
```

**Step 3: Verify popup works**

Run: Open neovim, press `<leader>rc` on a word
Expected: Popup appears with "<word> -> ", can edit, :w or <C-s> closes and shows lines

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/ui.lua nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): add popup UI component"
```

---

### Task 7: Wire up popup with input prompt

**Files:**
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Update replace_casing to prompt then show popup**

Replace `M.replace_casing` in `nvim/lua/smart-replace/init.lua`:

```lua
function M.replace_casing()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ui = require('smart-replace.ui')
  ui.prompt_replacement(source, function(replacement)
    local initial = source .. ' -> ' .. replacement
    ui.open_replace_popup(initial, function(lines)
      vim.notify('Would replace: ' .. vim.inspect(lines))
    end)
  end)
end
```

**Step 2: Verify full flow**

Run:
1. Press `<leader>rc` on a word
2. Enter replacement in input, press Enter
3. Edit popup content if desired
4. Press :w or <C-s>

Expected: Shows notification with replacement mappings

**Step 3: Commit**

```bash
git add nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): wire popup with input prompt"
```

---

### Task 8: Parse popup lines and execute replacements

**Files:**
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Add function to parse mapping lines**

Add to `nvim/lua/smart-replace/init.lua` after `do_replace`:

```lua
local function parse_mapping_line(line)
  -- Parse "source -> replacement" format
  local source, replacement = line:match('^%s*(.-)%s*->%s*(.-)%s*$')
  if source and replacement and source ~= '' and replacement ~= '' then
    return source, replacement
  end
  return nil, nil
end

local function do_replace_batch(mappings)
  -- Group all replacements into single undo block
  vim.cmd('undojoin')

  local total_count = 0
  for _, mapping in ipairs(mappings) do
    local source, replacement = mapping.source, mapping.replacement
    local escaped_source = escape_pattern(source)
    local escaped_replacement = replacement:gsub('/', '\\/')

    -- Count matches
    local count = 0
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for _, line in ipairs(lines) do
      local _, matches = line:gsub(vim.pesc(source), '')
      count = count + matches
    end

    if count > 0 then
      -- Perform replacement silently
      vim.cmd('silent! :%s/\\V' .. escaped_source .. '/' .. escaped_replacement .. '/g')
      total_count = total_count + count
    end
  end

  if total_count == 0 then
    vim.notify('No matches found', vim.log.levels.WARN)
  else
    vim.notify('Replaced ' .. total_count .. ' occurrence' .. (total_count == 1 and '' or 's'))
  end
end
```

**Step 2: Update replace_casing to use batch replace**

Replace the popup callback in `M.replace_casing`:

```lua
function M.replace_casing()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ui = require('smart-replace.ui')
  ui.prompt_replacement(source, function(replacement)
    local initial = source .. ' -> ' .. replacement
    ui.open_replace_popup(initial, function(lines)
      local mappings = {}
      for _, line in ipairs(lines) do
        local src, repl = parse_mapping_line(line)
        if src and repl then
          table.insert(mappings, { source = src, replacement = repl })
        end
      end

      if #mappings == 0 then
        vim.notify('No valid mappings found', vim.log.levels.WARN)
        return
      end

      do_replace_batch(mappings)
    end)
  end)
end
```

**Step 3: Verify batch replacement**

Run:
1. Create file with: `foo bar FOO baz foo_bar`
2. Press `<leader>rc` on `foo`
3. Enter `qux`, press Enter
4. Edit popup to have multiple lines:
   ```
   foo -> qux
   FOO -> QUX
   ```
5. Press :w

Expected: `foo` becomes `qux`, `FOO` becomes `QUX`

**Step 4: Verify undo works as single operation**

Run: After previous test, press `u` once
Expected: All replacements undone in one undo

**Step 5: Commit**

```bash
git add nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): parse popup and execute batch replacements with single undo"
```

---

## Phase 2: Smart Case Detection

### Task 9: Create case detection module

**Files:**
- Create: `nvim/lua/smart-replace/case.lua`

**Step 1: Create case module with detection logic**

Create `nvim/lua/smart-replace/case.lua`:

```lua
local M = {}

-- Detect the case style of a string
function M.detect_style(str)
  if str:match('^%u+$') then
    return 'SCREAMING_SNAKE' -- All uppercase, no separators
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

-- Split string into words based on detected style
function M.split_words(str)
  local style = M.detect_style(str)
  local words = {}

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
    -- Handle acronyms: HTTPMethod -> ["HTTP", "Method"]
    local i = 1
    local len = #str
    while i <= len do
      local char = str:sub(i, i)
      if char:match('%u') then
        -- Start of uppercase sequence
        local j = i + 1
        while j <= len and str:sub(j, j):match('%u') do
          j = j + 1
        end
        -- j now points to first non-uppercase or past end
        if j > i + 1 and j <= len and str:sub(j, j):match('%l') then
          -- Acronym followed by lowercase: HTTPMethod
          -- Take all but last uppercase as acronym
          table.insert(words, str:sub(i, j - 2):lower())
          i = j - 1
        elseif j > i + 1 then
          -- All uppercase to end or followed by non-letter
          table.insert(words, str:sub(i, j - 1):lower())
          i = j
        else
          -- Single uppercase followed by lowercase: normal word
          local k = j
          while k <= len and str:sub(k, k):match('%l') do
            k = k + 1
          end
          table.insert(words, str:sub(i, k - 1):lower())
          i = k
        end
      else
        -- Lowercase sequence
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

  return words
end

return M
```

**Step 2: Test detection manually**

Run in neovim command line:
```
:lua print(vim.inspect(require('smart-replace.case').split_words('someValue')))
:lua print(vim.inspect(require('smart-replace.case').split_words('HTTPMethod')))
:lua print(vim.inspect(require('smart-replace.case').split_words('parseJSON')))
:lua print(vim.inspect(require('smart-replace.case').split_words('some_value')))
```

Expected:
- `someValue` -> `{"some", "value"}`
- `HTTPMethod` -> `{"http", "method"}`
- `parseJSON` -> `{"parse", "json"}`
- `some_value` -> `{"some", "value"}`

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
-- Check if a word was originally an acronym (all uppercase in original)
local function is_acronym(word, original_words, index)
  -- This is called with lowercase words, but we track acronyms separately
  return word.is_acronym
end

-- Convert words array to various case styles
function M.to_camel_case(words, acronyms)
  acronyms = acronyms or {}
  local result = {}
  for i, word in ipairs(words) do
    if i == 1 then
      if acronyms[i] then
        table.insert(result, word:lower())
      else
        table.insert(result, word:lower())
      end
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

-- Generate all case variants from words
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

**Step 2: Test conversions manually**

Run:
```
:lua local c = require('smart-replace.case'); print(vim.inspect(c.generate_variants({'some', 'value'})))
```

Expected: Table with all 7 variants

**Step 3: Commit**

```bash
git add nvim/lua/smart-replace/case.lua
git commit -m "feat(smart-replace): add case conversion functions"
```

---

### Task 11: Improve acronym detection and tracking

**Files:**
- Modify: `nvim/lua/smart-replace/case.lua`

**Step 1: Update split_words to track acronyms**

Replace `M.split_words` function:

```lua
-- Split string into words based on detected style
-- Returns { words = {...}, acronyms = {[index] = true, ...} }
function M.split_words(str)
  local style = M.detect_style(str)
  local words = {}
  local acronyms = {}

  if style == 'snake_case' or style == 'SCREAMING_SNAKE' then
    local idx = 1
    for word in str:gmatch('[^_]+') do
      table.insert(words, word:lower())
      -- In SCREAMING_SNAKE, we can't distinguish acronyms
      idx = idx + 1
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
    -- Handle acronyms: HTTPMethod -> ["HTTP", "Method"]
    local i = 1
    local len = #str
    local word_idx = 0
    while i <= len do
      local char = str:sub(i, i)
      if char:match('%u') then
        word_idx = word_idx + 1
        -- Start of uppercase sequence
        local j = i + 1
        while j <= len and str:sub(j, j):match('%u') do
          j = j + 1
        end
        -- j now points to first non-uppercase or past end
        if j > i + 1 and j <= len and str:sub(j, j):match('%l') then
          -- Acronym followed by lowercase: HTTPMethod
          -- Take all but last uppercase as acronym
          table.insert(words, str:sub(i, j - 2):lower())
          acronyms[word_idx] = true
          i = j - 1
        elseif j > i + 1 then
          -- All uppercase to end: parseJSON
          table.insert(words, str:sub(i, j - 1):lower())
          acronyms[word_idx] = true
          i = j
        else
          -- Single uppercase followed by lowercase: normal word
          local k = j
          while k <= len and str:sub(k, k):match('%l') do
            k = k + 1
          end
          table.insert(words, str:sub(i, k - 1):lower())
          i = k
        end
      else
        -- Lowercase sequence (first word in camelCase)
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
```

**Step 2: Test acronym tracking**

Run:
```
:lua print(vim.inspect(require('smart-replace.case').split_words('HTTPMethod')))
:lua print(vim.inspect(require('smart-replace.case').split_words('parseJSON')))
```

Expected:
- `HTTPMethod` -> `{ words = {"http", "method"}, acronyms = {[1] = true} }`
- `parseJSON` -> `{ words = {"parse", "json"}, acronyms = {[2] = true} }`

**Step 3: Commit**

```bash
git add nvim/lua/smart-replace/case.lua
git commit -m "feat(smart-replace): track acronyms in word splitting"
```

---

### Task 12: Integrate smart case into replace_casing

**Files:**
- Modify: `nvim/lua/smart-replace/init.lua`

**Step 1: Update replace_casing to generate variants**

Replace `M.replace_casing` function:

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
    -- Parse source and replacement into words
    local source_parsed = case.split_words(source)
    local replacement_parsed = case.split_words(replacement)

    -- Generate all variants for both
    local source_variants = case.generate_variants(source_parsed.words, source_parsed.acronyms)
    local replacement_variants = case.generate_variants(replacement_parsed.words, replacement_parsed.acronyms)

    -- Build initial popup content
    local lines = {}
    for i, sv in ipairs(source_variants) do
      local rv = replacement_variants[i]
      table.insert(lines, sv.value .. ' -> ' .. rv.value)
    end

    local initial = table.concat(lines, '\n')

    ui.open_replace_popup(initial, function(popup_lines)
      local mappings = {}
      for _, line in ipairs(popup_lines) do
        local src, repl = parse_mapping_line(line)
        if src and repl then
          table.insert(mappings, { source = src, replacement = repl })
        end
      end

      if #mappings == 0 then
        vim.notify('No valid mappings found', vim.log.levels.WARN)
        return
      end

      do_replace_batch(mappings)
    end)
  end)
end
```

**Step 2: Verify smart replacement**

Run:
1. Create file with:
   ```
   const someValue = 1;
   const SOME_VALUE = 2;
   const some_value = 3;
   ```
2. Place cursor on `someValue`, press `<leader>rc`
3. Type `otherThing`, press Enter
4. Verify popup shows all variants:
   ```
   someValue -> otherThing
   SomeValue -> OtherThing
   some_value -> other_thing
   SOME_VALUE -> OTHER_THING
   some-value -> other-thing
   Some Value -> Other Thing
   some value -> other thing
   ```
5. Press :w

Expected: All matching variants replaced

**Step 3: Verify acronym handling**

Run:
1. Create file with:
   ```
   parseJSON();
   ParseJSON();
   parse_json();
   ```
2. Place cursor on `parseJSON`, press `<leader>rc`
3. Type `formatXML`, press Enter
4. Verify popup shows:
   ```
   parseJSON -> formatXML
   ParseJSON -> FormatXML
   ...
   ```

Expected: Acronyms preserved correctly in output

**Step 4: Commit**

```bash
git add nvim/lua/smart-replace/init.lua
git commit -m "feat(smart-replace): integrate smart case detection into popup flow"
```

---

### Task 13: Final polish and testing

**Files:**
- Modify: `nvim/lua/smart-replace/ui.lua` (resize popup for more lines)

**Step 1: Increase popup height for 7 variants**

Update popup size in `M.open_replace_popup`:

```lua
    size = {
      width = 60,
      height = 12,
    },
```

**Step 2: Full integration test**

Run complete workflow:
1. Create test file with mixed case styles
2. Test `<leader>rw` (basic replace) - should still work
3. Test `<leader>rc` (smart replace) - should show all variants
4. Test visual selection mode for both
5. Test undo after batch replace

**Step 3: Commit**

```bash
git add nvim/lua/smart-replace/ui.lua
git commit -m "feat(smart-replace): polish popup size for variant display"
```

---

## Summary

After completing all tasks:

| Keybinding | Function | Phase |
|------------|----------|-------|
| `<leader>rw` | Basic exact replace | 1 |
| `<leader>rc` | Smart case-aware popup replace | 2 |

**Files created:**
- `nvim/lua/custom/plugins/smart-replace.lua`
- `nvim/lua/smart-replace/init.lua`
- `nvim/lua/smart-replace/ui.lua`
- `nvim/lua/smart-replace/case.lua`

**Follow-up tasks (not in this plan):**
1. Scope toggle (file/project)
2. Customizable keybindings
3. Preview match count
4. Extract to standalone repo
