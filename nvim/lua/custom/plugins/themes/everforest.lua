return {
  'sainnhe/everforest',
  lazy = false,
  priority = 1000,
  config = function()
    -- Optionally configure and load the colorscheme
    -- directly inside the plugin declaration.
    vim.g.everforest_enable_italic = true

    -- Override line number colors for higher contrast
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = 'everforest',
      callback = function()
        vim.api.nvim_set_hl(0, 'LineNr', { fg = '#9da9a0' })
        vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#e69875', bold = true })
      end,
    })
  end,
}
