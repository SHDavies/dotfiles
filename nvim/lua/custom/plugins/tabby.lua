return {
  'nanozuki/tabby.nvim',
  event = 'VimEnter',
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- For file icons
  },
  config = function()
    local theme = {
      fill = 'TabLineFill',
      head = 'TabLine',
      current_tab = 'TabLineSel',
      tab = 'TabLine',
      win = 'TabLine',
      tail = 'TabLine',
    }

    require('tabby.tabline').set(function(line)
      return {
        -- Left side: Tab labels
        {
          { '  ', hl = theme.head },
        },
        line.tabs().foreach(function(tab)
          local hl = tab.is_current() and theme.current_tab or theme.tab

          -- Get project name from tab's working directory
          local cwd = vim.fn.getcwd(-1, tab.number())
          local project_name = vim.fn.fnamemodify(cwd, ':t')

          return {
            line.sep(' ', hl, theme.fill),
            tab.is_current() and '' or '',
            ' ',
            tab.number(),
            ' ',
            project_name,
            line.sep('', hl, theme.fill),
            hl = hl,
            margin = ' ',
          }
        end),

        -- Spacer between tabs and buffers
        line.spacer(),

        -- Right side: Buffers in active tab
        line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
          local hl = win.is_current() and theme.current_tab or theme.win
          return {
            line.sep(' ', hl, theme.fill),
            win.buf_name(),
            hl = hl,
          }
        end),

        {
          line.sep('', theme.tail, theme.fill),
          { '  ', hl = theme.tail },
        },
        hl = theme.fill,
      }
    end)
  end,
  keys = {
    -- Tab navigation (similar to your barbar bindings)
    { '<A-,>', '<cmd>tabprevious<cr>', desc = 'Previous Tab' },
    { '<A-.>', '<cmd>tabnext<cr>', desc = 'Next Tab' },

    -- Move tabs
    { '<A-<>', '<cmd>-tabmove<cr>', desc = 'Move Tab Left' },
    { '<A->>', '<cmd>+tabmove<cr>', desc = 'Move Tab Right' },

    -- Go to specific tab number
    { '<A-1>', '<cmd>tabnext 1<cr>', desc = 'Go to Tab 1' },
    { '<A-2>', '<cmd>tabnext 2<cr>', desc = 'Go to Tab 2' },
    { '<A-3>', '<cmd>tabnext 3<cr>', desc = 'Go to Tab 3' },
    { '<A-4>', '<cmd>tabnext 4<cr>', desc = 'Go to Tab 4' },
    { '<A-5>', '<cmd>tabnext 5<cr>', desc = 'Go to Tab 5' },
    { '<A-6>', '<cmd>tabnext 6<cr>', desc = 'Go to Tab 6' },
    { '<A-7>', '<cmd>tabnext 7<cr>', desc = 'Go to Tab 7' },
    { '<A-8>', '<cmd>tabnext 8<cr>', desc = 'Go to Tab 8' },
    { '<A-9>', '<cmd>tabnext 9<cr>', desc = 'Go to Tab 9' },
    { '<A-0>', '<cmd>tablast<cr>', desc = 'Go to Last Tab' },

    -- Close tab (with confirmation if modified)
    { '<A-c>', '<cmd>tabclose<cr>', desc = 'Close Tab' },

    -- Buffer picker in current tab (repurpose Ctrl+P)
    { '<C-p>', function() Snacks.picker.buffers() end, desc = 'Pick Buffer' },

    -- Additional useful tab commands
    { '<leader>tn', '<cmd>tabnew<cr>', desc = '[T]ab [N]ew' },
    { '<leader>to', '<cmd>tabonly<cr>', desc = '[T]ab [O]nly (close others)' },
  },
}

