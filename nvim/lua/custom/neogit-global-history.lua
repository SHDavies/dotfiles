-- Global commit message history for neogit.
-- Persists every submitted commit message to a single file across all
-- repositories, and adds <M-P>/<M-N> keybindings in gitcommit buffers to
-- cycle through that history. Parallel to neogit's built-in <m-p>/<m-n>,
-- which only reads `git log` of the current repo.

local M = {}

local HISTORY_FILE = vim.fn.stdpath 'state' .. '/neogit-commit-history.txt'
local DELIM = '<<<NEOGIT-COMMIT-HISTORY-DELIM>>>'

local function read_history()
  local f = io.open(HISTORY_FILE, 'r')
  if not f then
    return {}
  end
  local content = f:read '*a'
  f:close()
  if not content or content == '' then
    return {}
  end

  local messages = {}
  local current = {}
  for line in (content .. '\n'):gmatch '([^\n]*)\n' do
    if line == DELIM then
      while #current > 0 and current[#current]:match '^%s*$' do
        table.remove(current)
      end
      if #current > 0 then
        table.insert(messages, table.concat(current, '\n'))
      end
      current = {}
    else
      table.insert(current, line)
    end
  end
  return messages
end

local function append_history(message)
  vim.fn.mkdir(vim.fn.fnamemodify(HISTORY_FILE, ':h'), 'p')
  local f = io.open(HISTORY_FILE, 'a')
  if not f then
    return
  end
  f:write(message)
  f:write('\n' .. DELIM .. '\n')
  f:close()
end

-- Use neogit's resolved comment char if available; '#' otherwise.
local function comment_char()
  local ok, git = pcall(require, 'neogit.lib.git')
  if ok then
    local cfg_ok, c = pcall(function()
      return git.config.get('core.commentChar'):read()
    end)
    if cfg_ok and c and c ~= '' then
      return c
    end
  end
  return '#'
end

local function first_comment_line(lines, char)
  for i, line in ipairs(lines) do
    if line:sub(1, #char) == char then
      return i
    end
  end
  return #lines + 1
end

local function get_message_lines(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local cutoff = first_comment_line(lines, comment_char())
  local msg = {}
  for i = 1, cutoff - 1 do
    msg[i] = lines[i]
  end
  while #msg > 0 and msg[#msg]:match '^%s*$' do
    table.remove(msg)
  end
  return msg
end

local function set_message_lines(bufnr, new_lines)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local cutoff = first_comment_line(lines, comment_char())
  local replacement = {}
  for i, l in ipairs(new_lines) do
    replacement[i] = l
  end
  table.insert(replacement, '')
  vim.api.nvim_buf_set_lines(bufnr, 0, cutoff - 1, false, replacement)
end

local function setup_buffer(bufnr)
  local history = read_history()
  local index = #history + 1
  local saved_draft = nil
  local pending = nil

  local function show(target)
    if target < 1 then
      target = 1
    end
    if target > #history + 1 then
      target = #history + 1
    end
    if target == index then
      return
    end

    if index == #history + 1 then
      saved_draft = get_message_lines(bufnr)
    end

    index = target

    if index == #history + 1 then
      set_message_lines(bufnr, saved_draft or { '' })
    else
      set_message_lines(bufnr, vim.split(history[index], '\n', { plain = true }))
    end
    pcall(vim.api.nvim_win_set_cursor, 0, { 1, 0 })
  end

  vim.keymap.set('n', '<M-P>', function()
    show(index - 1)
  end, { buffer = bufnr, desc = 'Neogit: previous global commit message' })
  vim.keymap.set('n', '<M-N>', function()
    show(index + 1)
  end, { buffer = bufnr, desc = 'Neogit: next global commit message' })

  local group = vim.api.nvim_create_augroup('NeogitGlobalCommitHistory_' .. bufnr, { clear = true })

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    buffer = bufnr,
    callback = function()
      pending = get_message_lines(bufnr)
    end,
  })

  -- NeogitCommitComplete only fires when the commit actually succeeds, so a
  -- buffer write followed by abort never makes it into history.
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'NeogitCommitComplete',
    once = true,
    callback = function()
      if not pending or #pending == 0 then
        return
      end
      local message = table.concat(pending, '\n')
      if message:match '^%s*$' then
        return
      end

      local fresh = read_history()
      if fresh[#fresh] == message then
        return
      end
      append_history(message)
    end,
  })

  vim.api.nvim_create_autocmd('BufUnload', {
    group = group,
    buffer = bufnr,
    once = true,
    callback = function()
      vim.defer_fn(function()
        pcall(vim.api.nvim_del_augroup_by_id, group)
      end, 500)
    end,
  })
end

function M.setup()
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('NeogitGlobalCommitHistory', { clear = true }),
    pattern = 'gitcommit',
    callback = function(args)
      setup_buffer(args.buf)
    end,
  })
end

M.setup()

return M
