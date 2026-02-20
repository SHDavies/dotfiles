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

-- Ruby Indent Fixer
-- Re-indents the entire file based on block structure without applying other formatting

local function fix_ruby_indent()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local indent_width = vim.bo.shiftwidth

  -- Block-opening keywords (must be first token on line)
  local block_openers = {
    'class', 'module', 'def', 'if', 'unless', 'case',
    'while', 'until', 'for', 'begin',
  }

  -- Mid-block keywords: dedent for this line, re-indent for next
  local mid_block_keywords = { 'else', 'elsif', 'when', 'in', 'rescue', 'ensure' }

  -- Count closing brackets at the very start of a line (before any other content)
  local function count_leading_closes(code)
    local count = 0
    for i = 1, #code do
      local c = code:sub(i, i)
      if c == ')' or c == ']' or c == '}' then
        count = count + 1
      else
        break
      end
    end
    return count
  end

  -- Count net bracket delta (opens minus closes) for an entire line
  local function count_bracket_delta(code)
    local delta = 0
    for i = 1, #code do
      local c = code:sub(i, i)
      if c == '(' or c == '[' or c == '{' then
        delta = delta + 1
      elseif c == ')' or c == ']' or c == '}' then
        delta = delta - 1
      end
    end
    return delta
  end

  local indent_level = 0
  local in_heredoc = false
  local heredoc_delimiter = nil
  local new_lines = {}

  -- Save cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)

  for _, line in ipairs(lines) do
    -- Heredoc content: preserve as-is
    if in_heredoc then
      table.insert(new_lines, line)
      if line:match('^%s*' .. heredoc_delimiter .. '%s*$') then
        in_heredoc = false
        heredoc_delimiter = nil
      end
      goto continue
    end

    -- Blank lines stay blank
    if line:match('^%s*$') then
      table.insert(new_lines, '')
      goto continue
    end

    -- Strip leading whitespace to get content
    local content = line:match('^%s*(.*)')

    -- Prepare code for keyword matching (strip strings and comments)
    local code = content:gsub('"[^"]*"', '""'):gsub("'[^']*'", "''"):gsub('#.*$', '')

    -- Classify the line
    local is_end = code:match('^end%f[%W]') ~= nil

    local is_mid = false
    for _, kw in ipairs(mid_block_keywords) do
      if code:match('^' .. kw .. '%f[%W]') then
        is_mid = true
        break
      end
    end

    local leading_closes = count_leading_closes(code)

    -- Step 1: Dedent for this line (keywords + leading closing brackets)
    local keyword_dedent = 0
    if is_end or is_mid then
      keyword_dedent = 1
    end
    indent_level = math.max(0, indent_level - keyword_dedent - leading_closes)

    -- Step 2: Write the re-indented line
    table.insert(new_lines, string.rep(' ', indent_level * indent_width) .. content)

    -- Check for heredoc start (so we preserve subsequent heredoc content)
    local heredoc_match = code:match('<<[~-]?([%w_]+)')
    if heredoc_match then
      in_heredoc = true
      heredoc_delimiter = heredoc_match
    end

    -- Step 3: Indent changes for subsequent lines

    -- Keyword-based
    if is_mid then
      indent_level = indent_level + 1
    elseif not is_end then
      local opens = false
      for _, kw in ipairs(block_openers) do
        if code:match('^' .. kw .. '%f[%W]') then
          opens = true
          break
        end
      end

      if not opens then
        if code:match('%f[%w]do%s*|') or code:match('%f[%w]do%s*$') then
          opens = true
        end
      end

      if opens then
        local has_inline_end = code:match('%f[%w]end%f[%W]') and not code:match('^end%f[%W]')
        if not has_inline_end then
          indent_level = indent_level + 1
        end
      end
    end

    -- Bracket-based: net delta minus the leading closers already handled above
    local net_delta = count_bracket_delta(code)
    local remaining_delta = net_delta + leading_closes
    indent_level = math.max(0, indent_level + remaining_delta)

    ::continue::
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)

  -- Restore cursor position (clamp row to new line count)
  local max_row = #new_lines
  cursor[1] = math.min(cursor[1], max_row)
  vim.api.nvim_win_set_cursor(0, cursor)
end

-- Keybindings
vim.keymap.set('n', '<leader>re', fix_ruby_ends, { buffer = true, desc = 'Fix Ruby ends' })
vim.keymap.set('n', '<leader>ri', fix_ruby_indent, { buffer = true, desc = 'Fix Ruby indentation' })
