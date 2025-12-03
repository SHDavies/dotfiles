-- Custom keymaps
-- See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
-- See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })

vim.keymap.set('n', '<C-s>', '<cmd>w<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

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

vim.keymap.set('i', '<C-z>', '<C-o>u')

function _G.CopyBufferName()
  local filepath = vim.fn.expand '%'
  vim.fn.setreg('+', '"' .. filepath .. '"')
end

vim.keymap.set('n', '<leader>cp', CopyBufferName, { desc = 'Copy current path' })
