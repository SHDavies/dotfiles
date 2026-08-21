-- Custom keymaps
-- See `:help vim.keymap.set()`

vim.keymap.set('n', '<C-s>', '<cmd>w<cr>')

-- Move by display lines when wrapped, unless a count is given (so 5j etc. still work with relative numbers)
vim.keymap.set({ 'n', 'v' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = 'Down (respect wrap)' })
vim.keymap.set({ 'n', 'v' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = 'Up (respect wrap)' })

-- Likewise for start/end of line. Normal mode only, so operator-pending is left
-- alone and d$/c$/y$ still act on the whole logical line.
vim.keymap.set('n', '0', 'g0', { desc = 'Start of display line' })
vim.keymap.set('n', '$', "v:count == 0 ? 'g$' : '$'", { expr = true, desc = 'End of display line' })

-- Clear highlights on search when pressing <Esc> in normal mode
-- See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Quickfix list navigation. Telescope's <C-q> dumps a picker's results here, so
-- the list doubles as a persistent, editable view of a search.
vim.keymap.set('n', ']q', '<cmd>cnext<cr>zz', { desc = 'Next quickfix item' })
vim.keymap.set('n', '[q', '<cmd>cprev<cr>zz', { desc = 'Previous quickfix item' })
vim.keymap.set('n', ']Q', '<cmd>clast<cr>zz', { desc = 'Last quickfix item' })
vim.keymap.set('n', '[Q', '<cmd>cfirst<cr>zz', { desc = 'First quickfix item' })

vim.keymap.set('n', '<leader>sq', function()
  -- getwininfo marks location list windows as quickfix too, so exclude them --
  -- otherwise an open diagnostic loclist would make this close nothing.
  local is_open = vim.iter(vim.fn.getwininfo()):any(function(win)
    return win.quickfix == 1 and win.loclist == 0
  end)

  vim.cmd(is_open and 'cclose' or 'copen')
end, { desc = '[S]earch results: toggle [Q]uickfix' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>', { desc = 'Disabled: use h' })
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>', { desc = 'Disabled: use l' })
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>', { desc = 'Disabled: use k' })
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>', { desc = 'Disabled: use j' })

-- Keybinds to make split navigation easier.
-- Use CTRL+<hjkl> to switch between windows
-- See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Comment toggle with Ctrl+/
-- Note: In most terminals, Ctrl+/ is sent as Ctrl+_
-- Requires mini.comment to be set up (see lua/custom/plugins/mini.lua)
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<C-_>', 'gc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('v', '<C-/>', 'gc', { remap = true, desc = 'Toggle comment' })

-- Indent/outdent in visual mode (Tab/Shift-Tab)
-- After indenting, reselect the visual selection to allow repeated indenting
vim.keymap.set('v', '<Tab>', '>gv', { desc = 'Indent line' })
vim.keymap.set('v', '<S-Tab>', '<gv', { desc = 'Outdent line' })

vim.keymap.set('n', '<Tab>', '>>', { desc = 'Indent line' })
vim.keymap.set('n', '<S-Tab>', '<<', { desc = 'Outdent line' })

-- Restore <C-i> jump forward (since <Tab> is remapped above)
-- Requires a terminal with CSI u / Kitty keyboard protocol support (Ghostty, Kitty, WezTerm)
vim.keymap.set('n', '<C-i>', '<C-i>', { desc = 'Jump forward' })

-- Insert undo breakpoints after punctuation and whitespace
-- This makes undo more granular instead of undoing entire insert sessions
-- <C-g>u creates an undo breakpoint in insert mode

vim.keymap.set('i', '<Space>', '<Space><C-g>u')
vim.keymap.set('i', '<CR>', '<CR><C-g>u')

vim.keymap.set('i', ',', ',<C-g>u')
vim.keymap.set('i', '.', '.<C-g>u')
vim.keymap.set('i', '!', '!<C-g>u')
vim.keymap.set('i', '?', '?<C-g>u')
vim.keymap.set('i', ';', ';<C-g>u')
vim.keymap.set('i', ':', ':<C-g>u')

vim.keymap.set('i', '=', '=<C-g>u')
vim.keymap.set('i', '+', '+<C-g>u')
vim.keymap.set('i', '-', '-<C-g>u')
vim.keymap.set('i', '*', '*<C-g>u')
vim.keymap.set('i', '/', '/<C-g>u')
vim.keymap.set('i', '%', '%<C-g>u')
vim.keymap.set('i', '&', '&<C-g>u')
vim.keymap.set('i', '|', '|<C-g>u')

vim.keymap.set('i', ')', ')<C-g>u')
vim.keymap.set('i', ']', ']<C-g>u')
vim.keymap.set('i', '}', '}<C-g>u')

vim.keymap.set('i', '<C-j>', '<Esc>', { desc = 'Exit insert mode' })

vim.keymap.set('i', '<C-z>', '<C-o>u')

function _G.CopyBufferName()
  -- Derive the path from the buffer's full name rather than expand('%'), which
  -- returns the name as it was opened -- absolute when a plugin or the command
  -- line supplied an absolute path, and stale after the cwd changes.
  local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')
  vim.fn.setreg('+', filepath)
end

vim.keymap.set('n', '<leader>cp', CopyBufferName, { desc = 'Copy current path' })

-- Session management
vim.keymap.set('n', '<leader>sr', ':SessionRestore<CR>', { desc = 'Restore session' })
vim.keymap.set('n', '<leader>ss', ':SessionSave<CR>', { desc = 'Save session' })
