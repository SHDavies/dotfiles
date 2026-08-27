-- Tab-scoped diff review: a file panel plus real, syntax-highlighted buffers.
-- Installed as a Neogit dependency; this spec gives it its own lazy-load
-- triggers so the commands work without opening Neogit first.
return {
  'sindrets/diffview.nvim',
  cmd = {
    'DiffviewOpen',
    'DiffviewClose',
    'DiffviewFileHistory',
    'DiffviewFocusFiles',
    'DiffviewToggleFiles',
    'DiffviewRefresh',
  },
  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = 'Diff working tree' },
    { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'History of this file' },
    { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = 'History of this branch' },
    { '<leader>gh', ":<C-u>'<,'>DiffviewFileHistory<cr>", mode = 'v', desc = 'History of selected lines' },
  },
  opts = {
    enhanced_diff_hl = true,
    keymaps = {
      -- Diffview binds `q` in its option and help panels but not in the view
      -- itself. It cleans up its buffer-local maps on close.
      view = {
        { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' } },
      },
      file_panel = {
        { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' } },
      },
      file_history_panel = {
        { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' } },
      },
    },
  },
}
