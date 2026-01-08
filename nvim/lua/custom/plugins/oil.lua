return {
  'stevearc/oil.nvim',
  opts = {
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name)
        return name == '.git' or name == '.DS_Store'
      end,
    },
    float = {
      padding = 8,
      max_width = 0.8,
      max_height = 0.9,
      border = 'single',
      -- win_options = {
      --   winblend = 0,
      -- },
      -- get_win_title = nil,
      preview_split = 'auto',
    },
    confirmation = {
      border = 'single',
    },
  },
  dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
  lazy = false,
  keys = {
    { '-', '<cmd>Oil --float<cr>', desc = 'Open parent directory' },
  },
}
