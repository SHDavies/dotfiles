return {
  'MagicDuck/grug-far.nvim',
  -- Note (lazy loading): grug-far.lua defers all it's requires so it's lazy by default
  -- additional lazy config to defer loading is not really needed...
  opts = {
    windowCreationCommand = 'tab split',
  },
  keys = {
    { '<leader>sr', '<Cmd>GrugFar<cr>', desc = '[S]earch and [R]eplace' },
    {
      '<leader>sR',
      '<Cmd>lua require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })<cr>',
      desc = '[S]earch and [R]eplace current word',
    },
  },
}
