local M = {}

local function get_source_text()
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\22' then
    -- Visual mode: get selected text
    vim.cmd('noau normal! "vy')
    local text = vim.fn.getreg('v')
    vim.fn.setreg('v', {})
    return text
  else
    -- Normal mode: get word under cursor
    return vim.fn.expand('<cword>')
  end
end

function M.setup(opts)
  opts = opts or {}
  M.opts = opts
end

function M.replace_word()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end
  vim.notify('replace_word: ' .. source)
end

function M.replace_casing()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end
  vim.notify('replace_casing: ' .. source)
end

return M
