return {
  'romgrk/barbar.nvim',
  dependencies = {
    'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  },
  init = function()
    vim.g.barbar_auto_setup = false
  end,
  event = 'BufEnter',
  keys = {
    { '<A-,>', '<Cmd>BufferPrevious<CR>' },
    { '<A-.>', '<Cmd>BufferNext<CR>' },
    { '<A-<>', '<Cmd>BufferMovePrevious<CR>' },
    { '<A->>', '<Cmd>BufferMoveNext<CR>' },
    { '<A-1>', '<Cmd>BufferGoto 1<CR>' },
    { '<A-2>', '<Cmd>BufferGoto 2<CR>' },
    { '<A-3>', '<Cmd>BufferGoto 3<CR>' },
    { '<A-4>', '<Cmd>BufferGoto 4<CR>' },
    { '<A-5>', '<Cmd>BufferGoto 5<CR>' },
    { '<A-6>', '<Cmd>BufferGoto 6<CR>' },
    { '<A-7>', '<Cmd>BufferGoto 7<CR>' },
    { '<A-8>', '<Cmd>BufferGoto 8<CR>' },
    { '<A-9>', '<Cmd>BufferGoto 9<CR>' },
    { '<A-0>', '<Cmd>BufferLast<CR>' },
    { '<A-c>', '<Cmd>BufferClose<CR>' },
    { '<A-r>', '<Cmd>BufferRestore<CR>' },
    { '<A-o>', '<Cmd>BufferCloseAllButCurrent<CR>' },
    { '<C-p>', '<Cmd>BufferPick<CR>' },
    { '<C-P>', '<Cmd>BufferPickDelete<CR>' },
  },
  opts = {
    sidebar_filetypes = {
      ['neo-tree'] = { event = 'BufWipeout' },
    },
    auto_hide = 1,
  },
}

--
-- -- Pin/unpin buffer
-- map('n', '<A-p>', '<Cmd>BufferPin<CR>', opts)
--
-- -- Goto pinned/unpinned buffer
-- --                 :BufferGotoPinned
-- --                 :BufferGotoUnpinned
--
-- -- Close buffer
-- map('n', '<A-c>', '<Cmd>BufferClose<CR>', opts)
--
-- -- Wipeout buffer
-- --                 :BufferWipeout
--
-- -- Close commands
-- --                 :BufferCloseAllButCurrent
-- --                 :BufferCloseAllButPinned
-- --                 :BufferCloseAllButCurrentOrPinned
-- --                 :BufferCloseBuffersLeft
-- --                 :BufferCloseBuffersRight
--
-- -- Magic buffer-picking mode
-- map('n', '<C-p>',   '<Cmd>BufferPick<CR>', opts)
-- map('n', '<C-s-p>', '<Cmd>BufferPickDelete<CR>', opts)
--
-- -- Sort automatically by...
-- map('n', '<Space>bb', '<Cmd>BufferOrderByBufferNumber<CR>', opts)
-- map('n', '<Space>bn', '<Cmd>BufferOrderByName<CR>', opts)
-- map('n', '<Space>bd', '<Cmd>BufferOrderByDirectory<CR>', opts)
-- map('n', '<Space>bl', '<Cmd>BufferOrderByLanguage<CR>', opts)
-- map('n', '<Space>bw', '<Cmd>BufferOrderByWindowNumber<CR>', opts)
