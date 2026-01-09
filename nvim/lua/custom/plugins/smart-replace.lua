return {
  dir = vim.fn.stdpath('config') .. '/lua/smart-replace',
  name = 'smart-replace',
  dependencies = {
    'MunifTanjim/nui.nvim',
    {
      'SHDavies/muren.nvim',
      opts = {},
    },
  },
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
    {
      '<leader>rc',
      function()
        require('smart-replace').replace_casing_variants()
      end,
      mode = { 'n', 'v' },
      desc = '[R]eplace with [C]asing Variants',
    },
  },
}
