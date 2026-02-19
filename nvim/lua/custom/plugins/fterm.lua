return {
  'numToStr/FTerm.nvim',
  keys = {
    { '<A-i>', '<CMD>lua require("FTerm").toggle()<CR>' },
    { '<A-i>', '<CMD>lua require("FTerm").toggle()<CR>', mode = 't' },
    {
      '<leader>tt',
      function()
        local buf = vim.api.nvim_buf_get_name(0)
        require('FTerm').scratch {
          cmd = { 'bundle', 'exec', 'bench', buf },
          dimensions = { height = 0.9, width = 0.9 },
        }
      end,
    },
    {
      '<A-s>',
      function()
        require('server-terminal').toggle 'default'
      end,
      mode = { 'n', 't' },
      desc = 'Toggle server terminal (default)',
    },
    {
      '<A-S>',
      function()
        require('server-terminal').toggle 'alternate'
      end,
      mode = { 'n', 't' },
      desc = 'Toggle server terminal (alternate)',
    },
  },
  config = function()
    require('FTerm').setup {
      hl = 'FloatTermBg',
    }

    vim.api.nvim_create_autocmd('VimLeavePre', {
      callback = function()
        local ok, server_terminal = pcall(require, 'server-terminal')
        if ok then
          server_terminal.cleanup()
        end
      end,
    })
  end,
}
