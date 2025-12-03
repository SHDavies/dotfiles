vim.o.tabstop = 2 -- Number of spaces a <Tab> in the file counts for
vim.o.shiftwidth = 2 -- Number of spaces to use for each step of (auto)indent
vim.o.expandtab = true -- Use spaces instead of tabs
vim.o.softtabstop = 2 -- Number of spaces that a <Tab> counts for while editing

-- Enable visual soft wrapping
vim.opt_local.wrap = true

-- Wrap by word rather than character
vim.opt_local.linebreak = true

-- Maintain indentation of wrapped lines
vim.opt_local.breakindent = true

-- Remap j/k to move by *display* line (gj/gk) instead of *physical* line (j/k)
vim.keymap.set("n", "j", "gj", { buffer = true })
vim.keymap.set("n", "k", "gk", { buffer = true })
vim.keymap.set("n", "0", "g0", { buffer = true })
vim.keymap.set("n", "$", "g$", { buffer = true })
