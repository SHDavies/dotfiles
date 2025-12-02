return {
  's1n7ax/nvim-window-picker',
  opts = {
    hint = 'floating-letter',
    show_prompt = true,
    prompt_message = 'Pick window: ',
    filter_rules = {
      include_current_win = true,
      autoselect_one = false,
      -- filter using buffer options
      bo = {
        -- if the file type is one of following, the window will be ignored
        filetype = { 'neo-tree', 'neo-tree-popup', 'notify' },
        -- if the buffer type is one of following, the window will be ignored
        buftype = { 'terminal', 'quickfix' },
      },
    },
  },
}
