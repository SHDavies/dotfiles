return {
  'f-person/git-blame.nvim',
  opts = {
    enabled = false,
    date_format = '%a %b %d %Y',
  },
  keys = {
    { '<leader>gb', '<cmd>GitBlameToggle<cr>', desc = 'Toggle Git Blame' },
    { '<leader>gc', '<cmd>GitBlameOpenCommitURL<cr>', desc = 'Open Blame Commit URL' },
  },
}
