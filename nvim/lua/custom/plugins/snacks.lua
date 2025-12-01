return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 1000,
  ---@type snacks.Config
  opts = {
    -- Enable the picker module
    picker = {
      -- Use a clean layout that adapts to window size
      layout = {
        preset = function()
          return vim.o.columns >= 120 and 'default' or 'vertical'
        end,
      },
      -- Configure sources
      sources = {
        -- Projects picker configuration
        projects = {
          recent = false,
          patterns = { '.git', 'Gemfile', 'Gemfile.lock' },
          -- Custom confirm action: open project in new tab
          confirm = function(picker)
            vim.cmd 'tabnew' -- Create a new tab
            picker:action 'tcd' -- Set tab-local working directory to selected project
          end,
          -- Directory to scan for projects
          dev = { '~/wsgr/neuron' },
        },
      },
    },
    -- Enable other useful snacks modules (optional, but recommended)
    bigfile = { enabled = true }, -- Disable features in large files for performance
    notifier = { enabled = false }, -- Disabled - using noice.nvim + nvim-notify instead
    quickfile = { enabled = true }, -- Fast file opening
    statuscolumn = { enabled = true }, -- Better status column
    words = { enabled = true }, -- Highlight word under cursor
  },
  keys = {
    -- Project picker
    { '<leader>pp', function() Snacks.picker.projects() end, desc = '[P]ick [P]roject' },

    -- File pickers
    { '<leader>pf', function() Snacks.picker.files() end, desc = '[P]ick [F]iles' },
    { '<leader>pr', function() Snacks.picker.recent() end, desc = '[P]ick [R]ecent Files' },

    -- Search pickers
    { '<leader>pg', function() Snacks.picker.grep() end, desc = '[P]ick [G]rep' },
    { '<leader>pw', function() Snacks.picker.grep_word() end, desc = '[P]ick [W]ord under cursor' },

    -- Buffer picker
    { '<leader>pb', function() Snacks.picker.buffers() end, desc = '[P]ick [B]uffers' },

    -- Git pickers
    { '<leader>gc', function() Snacks.picker.git_log() end, desc = '[G]it [C]ommits' },
    { '<leader>gs', function() Snacks.picker.git_status() end, desc = '[G]it [S]tatus' },

    -- Neovim pickers
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>sc', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },

    -- Diagnostic pickers
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },

    -- Resume last picker
    { '<leader>p.', function() Snacks.picker.resume() end, desc = '[P]ick Resume Last' },
  },
}

