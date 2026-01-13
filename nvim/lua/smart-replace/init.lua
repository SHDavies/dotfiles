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

local function escape_pattern(text)
  return text:gsub('\\', '\\\\'):gsub('/', '\\/')
end

local function do_replace(source, replacement)
  local escaped_source = escape_pattern(source)
  local escaped_replacement = replacement:gsub('/', '\\/')

  -- Count matches first
  local count = 0
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local _, matches = line:gsub(vim.pesc(source), '')
    count = count + matches
  end

  if count == 0 then
    vim.notify('No matches found for "' .. source .. '"', vim.log.levels.WARN)
    return
  end

  vim.cmd(':%s/\\V' .. escaped_source .. '/' .. escaped_replacement .. '/g')
  vim.notify('Replaced ' .. count .. ' occurrence' .. (count == 1 and '' or 's'))
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

  local ui = require('smart-replace.ui')
  ui.prompt_replacement(source, function(replacement)
    do_replace(source, replacement)
  end)
end

function M.replace_casing_variants()
  local source = get_source_text()
  if source == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ui = require('smart-replace.ui')
  local case = require('smart-replace.case')

  ui.prompt_replacement(source, function(replacement)
    local source_style = case.detect_style(source)
    local source_parsed = case.split_words(source, source_style)
    local replacement_parsed = case.split_words(replacement, source_style)

    local source_variants = case.generate_variants(source_parsed.words, source_parsed.acronyms)
    local replacement_variants = case.generate_variants(replacement_parsed.words, replacement_parsed.acronyms)

    local patterns = {}
    local replacements = {}
    for i, sv in ipairs(source_variants) do
      table.insert(patterns, sv.value)
      table.insert(replacements, replacement_variants[i].value)
    end

    require('muren.api').open_ui({
      patterns = patterns,
      replacements = replacements,
    })
  end)
end

return M
