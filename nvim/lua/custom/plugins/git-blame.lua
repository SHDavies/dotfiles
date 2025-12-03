return {
  'f-person/git-blame.nvim',
  opts = {
    enabled = false,
    gitblame_remote_domains = 'github',
  },
  keys = {
    { '<leader>gb', '<cmd>GitBlameToggle<cr>', desc = 'Toggle Git Blame' },
    { '<leader>gc', '<cmd>GitBlameOpenCommitURL<cr>', desc = 'Open Blame Commit URL' },
  },
}
