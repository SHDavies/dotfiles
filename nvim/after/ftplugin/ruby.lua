-- Ruby End Fixer
-- Automatically fixes missing or extra `end` statements

local function fix_ruby_ends()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Block-opening keywords (must be first token on line)
  local first_token_keywords = {
    'class', 'module', 'def', 'if', 'unless', 'case',
    'while', 'until', 'for', 'begin'
  }

  -- Build pattern for first-token keywords
  local first_token_pattern = '^(%s*)(' .. table.concat(first_token_keywords, '|') .. ')%f[%W]'

  local stack = {} -- {keyword, indent, line_num}
  local extra_ends = {} -- line numbers of extra ends
  local insertions = {} -- {line_num, indent} for missing ends

  -- Simple state tracking
  local in_heredoc = false
  local heredoc_delimiter = nil

  for line_num, line in ipairs(lines) do
    -- Check for heredoc start
    if not in_heredoc then
      local heredoc_match = line:match('<<[~-]?([%w_]+)')
      if heredoc_match then
        in_heredoc = true
        heredoc_delimiter = heredoc_match
      end
    end

    -- Check for heredoc end
    if in_heredoc then
      if line:match('^%s*' .. heredoc_delimiter .. '%s*$') then
        in_heredoc = false
        heredoc_delimiter = nil
      end
      goto continue
    end

    -- Skip comment lines
    if line:match('^%s*#') then
      goto continue
    end

    -- Remove inline comments for parsing
    local code_line = line:gsub('#.*$', '')

    -- Remove string contents to avoid false matches
    code_line = code_line:gsub('"[^"]*"', '""')
    code_line = code_line:gsub("'[^']*'", "''")

    -- Get indentation
    local indent = #(line:match('^(%s*)') or '')

    -- Check for first-token keywords
    for _, keyword in ipairs(first_token_keywords) do
      local pattern = '^%s*' .. keyword .. '%f[%W]'
      if code_line:match(pattern) then
        -- Before pushing, check if we need to close anything at same/lesser indent
        while #stack > 0 and stack[#stack].indent >= indent do
          local unclosed = table.remove(stack)
          -- Insert end before this line
          table.insert(insertions, { line_num = line_num, indent = unclosed.indent })
        end
        table.insert(stack, { keyword = keyword, indent = indent, line_num = line_num })
        goto continue
      end
    end

    -- Check for `do` blocks (anywhere on line, followed by | or end of line)
    if code_line:match('%f[%w]do%s*|') or code_line:match('%f[%w]do%s*$') then
      -- Get indent of the line containing do
      while #stack > 0 and stack[#stack].indent >= indent do
        local unclosed = table.remove(stack)
        table.insert(insertions, { line_num = line_num, indent = unclosed.indent })
      end
      table.insert(stack, { keyword = 'do', indent = indent, line_num = line_num })
      goto continue
    end

    -- Check for `end`
    if code_line:match('^%s*end%f[%W]') then
      local end_indent = indent
      -- Before popping, check if stack top has greater indent than this end
      -- If so, those blocks should have closed first
      while #stack > 0 and stack[#stack].indent > end_indent do
        local unclosed = table.remove(stack)
        table.insert(insertions, { line_num = line_num, indent = unclosed.indent })
      end
      -- Now pop the matching opener
      if #stack > 0 then
        table.remove(stack)
      else
        table.insert(extra_ends, line_num)
      end
    end

    ::continue::
  end

  -- Remaining stack items need ends at end of file
  local eof_insertions = {}
  while #stack > 0 do
    local unclosed = table.remove(stack)
    table.insert(eof_insertions, unclosed.indent)
  end

  -- Apply changes (in reverse order to preserve line numbers)

  -- First, add ends at EOF
  for _, indent_level in ipairs(eof_insertions) do
    local end_line = string.rep(' ', indent_level) .. 'end'
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { end_line })
  end

  -- Sort insertions by line number (descending), then by indent (ascending)
  -- When multiple insertions at same line, insert outermost first so innermost ends up on top
  table.sort(insertions, function(a, b)
    if a.line_num ~= b.line_num then
      return a.line_num > b.line_num
    end
    return a.indent < b.indent
  end)

  -- Adjust insertion points to skip backwards over blank lines (using original buffer)
  for _, ins in ipairs(insertions) do
    local insert_at = ins.line_num
    while insert_at > 1 and lines[insert_at - 1]:match('^%s*$') do
      insert_at = insert_at - 1
    end
    ins.adjusted_line_num = insert_at
  end

  -- Insert missing ends (still going descending by original line_num)
  for _, ins in ipairs(insertions) do
    local end_line = string.rep(' ', ins.indent) .. 'end'
    vim.api.nvim_buf_set_lines(0, ins.adjusted_line_num - 1, ins.adjusted_line_num - 1, false, { end_line })
  end

  -- Sort extra ends (descending) to preserve line numbers
  table.sort(extra_ends, function(a, b) return a > b end)

  -- Remove extra ends (account for insertions that happened above them)
  for _, line_num in ipairs(extra_ends) do
    -- Count how many insertions happened before this line
    local offset = 0
    for _, ins in ipairs(insertions) do
      if ins.line_num <= line_num then
        offset = offset + 1
      end
    end
    vim.api.nvim_buf_set_lines(0, line_num - 1 + offset, line_num + offset, false, {})
  end

  -- Report what was done
  local changes = #insertions + #eof_insertions + #extra_ends
  if changes > 0 then
    local msg = {}
    if #insertions + #eof_insertions > 0 then
      table.insert(msg, 'Added ' .. (#insertions + #eof_insertions) .. ' end(s)')
    end
    if #extra_ends > 0 then
      table.insert(msg, 'Removed ' .. #extra_ends .. ' extra end(s)')
    end
    -- vim.notify(table.concat(msg, ', '), vim.log.levels.INFO)
  else
    -- vim.notify('No end fixes needed', vim.log.levels.INFO)
  end
end

-- Keybinding
vim.keymap.set('n', '<leader>re', fix_ruby_ends, { buffer = true, desc = 'Fix Ruby ends' })
