return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  -- opts = config,
  opts = {
    options = {
      disabled_filetypes = {
        statusline = { 'neo-tree' },
      },
      ignore_focus = { 'neo-tree' },
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff' },
      lualine_c = {
        -- Show current project name
        {
          function()
            local cwd = vim.fn.getcwd(-1, -1)
            local home = vim.fn.expand('~')
            local neuron_root = home .. '/wsgr/neuron'

            -- Check if we're in a project directory
            if cwd:find(neuron_root, 1, true) == 1 then
              -- Extract project name (directory name after neuron/)
              local project = cwd:gsub(neuron_root .. '/', ''):match('^([^/]+)')
              if project then
                return '󱃾 ' .. project
              end
            end

            -- Fallback: show directory name
            return '󱃾 ' .. vim.fn.fnamemodify(cwd, ':t')
          end,
          color = { fg = '#a7c080', gui = 'bold' }, -- Everforest green color
        },
        'filename',
      },
      lualine_x = { 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { 'filename' },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },
    theme = 'everforest',
  },
}
