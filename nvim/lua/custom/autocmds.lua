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

vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'BufWinLeave', 'TabLeave' }, {
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
