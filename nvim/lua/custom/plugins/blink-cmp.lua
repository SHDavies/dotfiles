-- Autocompletion
-- https://github.com/saghen/blink.cmp

return {
  'saghen/blink.cmp',
  event = 'VimEnter',
  version = '1.*',
  dependencies = {
    -- Snippet Engine
    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = (function()
        -- Build Step is needed for regex support in snippets.
        -- This step is not supported in many windows environments.
        -- Remove the below condition to re-enable on windows.
        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
      dependencies = {
        -- `friendly-snippets` contains a variety of premade snippets.
        --    See the README about individual language/framework/plugin snippets:
        --    https://github.com/rafamadriz/friendly-snippets
        -- {
        --   'rafamadriz/friendly-snippets',
        --   config = function()
        --     require('luasnip.loaders.from_vscode').lazy_load()
        --   end,
        -- },
      },
      opts = {},
    },
    'folke/lazydev.nvim',
    'mikavilpas/blink-ripgrep.nvim',
  },
  --- @module 'blink.cmp'
  --- @type blink.cmp.Config
  opts = {
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- For an understanding of why the 'default' preset is recommended,
      -- you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      preset = 'none', -- Disable preset so we can define custom mappings

      -- Cycle through completions with Tab/Shift-Tab with auto-insert
      ['<Tab>'] = {
        function(cmp)
          return cmp.select_next { auto_insert = true }
        end,
        'snippet_forward',
        'fallback',
      },
      ['<S-Tab>'] = {
        function(cmp)
          return cmp.select_prev { auto_insert = true }
        end,
        'snippet_backward',
        'fallback',
      },

      -- Accept with Space and insert a space character after accepting
      ['<Space>'] = {
        function(cmp)
          -- Only accept if menu is visible AND an item is selected
          if cmp.is_visible() and cmp.get_selected_item() then
            cmp.accept {
              callback = function()
                vim.api.nvim_feedkeys(' ', 'n', true)
              end,
            }
            return true
          end
          -- If menu is visible but nothing selected, or menu is hidden, insert space
        end,
        'fallback',
      },

      -- Accept with Enter
      ['<cr>'] = { 'accept', 'fallback' },

      -- Cancel/hide with Escape
      ['<Esc>'] = {
        function(cmp)
          if cmp.is_visible() and cmp.get_selected_item() then
            cmp.cancel()
            return true
          end
        end,
        'fallback',
      },

      -- Show/hide completion menu
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' },

      -- Navigate up/down
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback' },
      ['<C-n>'] = { 'select_next', 'fallback' },

      -- Scroll documentation
      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

      -- Toggle signature help
      ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
      list = {
        selection = {
          preselect = false,
        },
      },
    },

    sources = {
      default = { 'lsp', 'buffer', 'ripgrep', 'path', 'snippets', 'lazydev' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        ripgrep = {
          module = 'blink-ripgrep',
          name = 'Ripgrep',
          opts = {
            prefix_min_len = 3,
            backend = {
              use = 'gitgrep-or-ripgrep',
            },
          },
        },
      },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See :h blink-cmp-config-fuzzy for more information
    fuzzy = { implementation = 'lua' },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  },
}
