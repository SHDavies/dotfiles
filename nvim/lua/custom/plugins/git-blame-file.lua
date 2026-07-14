return {
  'SHDavies/git-blame-file',
  cmd = { 'GitBlameFile', 'GitBlameFileToggle', 'GitBlameFileOff' },
  keys = {
    { '<leader>gb', '<cmd>GitBlameFileToggle<cr>', desc = 'Toggle inline git blame' },
  },
  config = function()
    require('git-blame-file').setup {}
  end,
}
