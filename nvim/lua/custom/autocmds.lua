-- auto trim trailing whitespace and trailing newlines
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  pattern = { '*' },
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd [[%s/\s\+$//e]]
    vim.cmd [[%s/\n\+\%$//e]]
    vim.fn.winrestview(view)
  end,
  desc = 'Trim trailing whitespace and newlines',
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  desc = 'Attach keymaps for quickfix list',
  callback = function()
    vim.keymap.set('n', 'dd', function()
      local qf_list = vim.fn.getqflist()

      local current_line_number = vim.fn.line '.'

      if qf_list[current_line_number] then
        table.remove(qf_list, current_line_number)

        vim.fn.setqflist(qf_list, 'r')

        local new_line_number = math.min(current_line_number, #qf_list)
        vim.fn.cursor(new_line_number, 1)
      end
    end, {
      buffer = true,
      noremap = true,
      silent = true,
      desc = 'Remove quickfix item under cursor',
    })
  end,
})

-- Save on blur
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'BufWinLeave', 'TabLeave' }, {
  nested = true,
  callback = function()
    if vim.bo.modified and vim.bo.modifiable and vim.bo.buftype == '' then
      vim.cmd 'silent! write'
    end
  end,
})

-- Prevent oil buffers from appearing in barbar tabline
-- BufNew fires at buffer creation, before BufAdd and BufEnter
vim.api.nvim_create_autocmd({ 'BufNew', 'BufAdd' }, {
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    if bufname:match('^oil://') then
      vim.bo[args.buf].buflisted = false
    end
  end,
  desc = 'Prevent oil buffers from appearing in tabline',
})

-- Persistent undo with hashed filenames.
-- Neovim's native undofile encodes a buffer's full path into a single flat
-- filename (/ -> %). Deeply-nested paths (common in the neuron repo) exceed the
-- 255-byte filename limit on macOS, so writes fail with E828. Instead we store
-- undo history under a sha256 of the path (64 chars) and load/save it manually.
local undodir = vim.fn.stdpath('state') .. '/undo'
vim.fn.mkdir(undodir, 'p')

local function undofile_for(buf)
  if vim.bo[buf].buftype ~= '' then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return nil
  end
  return undodir .. '/' .. vim.fn.sha256(name)
end

vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('PersistentUndo', { clear = true }),
  callback = function(args)
    local file = undofile_for(args.buf)
    if file and vim.fn.filereadable(file) == 1 then
      vim.cmd('silent! rundo ' .. vim.fn.fnameescape(file))
    end
  end,
  desc = 'Load persistent undo history from hashed file',
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = 'PersistentUndo',
  callback = function(args)
    local file = undofile_for(args.buf)
    if file then
      vim.cmd('silent! wundo ' .. vim.fn.fnameescape(file))
    end
  end,
  desc = 'Save persistent undo history to hashed file',
})

-- Autorefresh buffers
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  group = vim.api.nvim_create_augroup('CheckForExternalChanges', { clear = true }),
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd('checktime')
    end
  end
})
