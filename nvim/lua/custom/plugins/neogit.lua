return {
  'NeogitOrg/neogit',
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'sindrets/diffview.nvim', -- optional - Diff integration

    -- Only one of these is needed.
    'nvim-telescope/telescope.nvim', -- optional
    'ibhagwan/fzf-lua', -- optional
    'nvim-mini/mini.pick', -- optional
    'folke/snacks.nvim', -- optional
  },
  cmd = 'Neogit',
  opts = {
    commit_view = {
      -- Neogit defaults this to a vsplit, which is too narrow to read a diff
      -- in. A tab gives the commit the full width, and matches log_view's own
      -- default kind, so `q` drops straight back to the log forest.
      kind = 'tab',
    },
    -- Off by default, which leaves hunks as unhighlighted plain text.
    treesitter_diff_highlight = true,
  },
  config = function(_, opts)
    require('neogit').setup(opts)

    -- Within the hunk under the cursor, Neogit paints the cursor's own line with
    -- NeogitDiff{Add,Delete}Cursor, which swap the diff background for a neutral
    -- one -- so green/red vanishes as the cursor passes over. Link them to their
    -- *Highlight counterparts to keep the color, matching how Neogit already
    -- defines NeogitHunkHeaderCursor identically to NeogitHunkHeaderHighlight.
    local function keep_diff_color_under_cursor()
      vim.api.nvim_set_hl(0, 'NeogitDiffAddCursor', { link = 'NeogitDiffAddHighlight' })
      vim.api.nvim_set_hl(0, 'NeogitDiffDeleteCursor', { link = 'NeogitDiffDeleteHighlight' })
    end

    keep_diff_color_under_cursor()

    -- A colorscheme change clears these, and Neogit re-defines its own on the
    -- same event.
    vim.api.nvim_create_autocmd('ColorScheme', {
      desc = 'Keep diff colors on the cursor line in Neogit buffers',
      callback = keep_diff_color_under_cursor,
    })
  end,
  keys = {
    { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Show Neogit UI' },
    {
      '<leader>gl',
      function()
        require('neogit').action('log', 'log_current', { '--graph', '--decorate', '--color' })()
      end,
      desc = 'Git log forest',
    },
  },
}
