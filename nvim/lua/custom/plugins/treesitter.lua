-- Highlight, edit, and navigate code
-- https://github.com/nvim-treesitter/nvim-treesitter
-- Uses the `main` branch, required for Neovim 0.12+.
-- Depends on the tree-sitter CLI (>= 0.26.1): `brew install tree-sitter`.

local parsers = {
  'bash',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  'ruby',
  'elixir',
}

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = function()
    require('nvim-treesitter').update()
  end,
  config = function()
    require('nvim-treesitter').install(parsers)

    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        local buf = args.buf
        if not pcall(vim.treesitter.start, buf) then
          return
        end
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if lang == 'ruby' then
          -- Keep Vim's regex syntax on alongside treesitter highlighting,
          -- and use Vim's built-in indent (matches prior `indent.disable = {'ruby'}`).
          vim.bo[buf].syntax = 'ON'
        else
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
