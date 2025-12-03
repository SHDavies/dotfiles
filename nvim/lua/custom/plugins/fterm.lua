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
  },
}
