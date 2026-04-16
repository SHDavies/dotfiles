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

-- <CR> toggles a GitHub-style task-list checkbox on the current line.
-- Matches bullet (-, *, +) and numbered (1., 1)) list markers. Falls through
-- to default <CR> behavior on non-checkbox lines.
vim.keymap.set("n", "<CR>", function()
  local line = vim.api.nvim_get_current_line()
  local patterns = {
    "^(%s*[-*+]%s+%[)([ xX])(%].*)$",
    "^(%s*%d+[.)]%s+%[)([ xX])(%].*)$",
  }
  for _, pattern in ipairs(patterns) do
    local prefix, state, suffix = line:match(pattern)
    if prefix then
      local new_state = state == " " and "x" or " "
      vim.api.nvim_set_current_line(prefix .. new_state .. suffix)
      return
    end
  end
  local keys = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end, { buffer = true, desc = "Toggle markdown checkbox" })
