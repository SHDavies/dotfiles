return {
  'vim-test/vim-test',
  config = function()
    vim.api.nvim_set_keymap('n', '<leader>tt', ':TestNearest<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>tf', ':TestFile<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>ts', ':TestSuite<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>tl', ':TestLast<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('t', '<C-o>', '<C-\\><C-n>', { noremap = true, silent = true })
    vim.g['test#ruby#testbench#file_pattern'] = '.rb'

    vim.g['test#strategy'] = {
      nearest = 'neovim',
      file = 'basic',
      suite = 'neovim',
    }
  end,
}
