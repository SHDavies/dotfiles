local M = {}

function M.detect_style(str)
  if str:match('^%u+$') then
    return 'SCREAMING_SNAKE'
  elseif str:match('^%l+$') then
    return 'lowercase'
  elseif str:match('_') then
    if str:match('^%u[%u_]*%u$') or str:match('^%u+_') then
      return 'SCREAMING_SNAKE'
    else
      return 'snake_case'
    end
  elseif str:match('%-') then
    return 'kebab-case'
  elseif str:match(' ') then
    if str:match('^%u') and str:match(' %u') then
      return 'Title Case'
    else
      return 'lowercase'
    end
  elseif str:match('^%u') then
    return 'PascalCase'
  elseif str:match('%u') then
    return 'camelCase'
  else
    return 'lowercase'
  end
end

function M.split_words(str)
  local style = M.detect_style(str)
  local words = {}
  local acronyms = {}

  if style == 'snake_case' or style == 'SCREAMING_SNAKE' then
    for word in str:gmatch('[^_]+') do
      table.insert(words, word:lower())
    end
  elseif style == 'kebab-case' then
    for word in str:gmatch('[^%-]+') do
      table.insert(words, word:lower())
    end
  elseif style == 'Title Case' or style == 'lowercase' then
    for word in str:gmatch('%S+') do
      table.insert(words, word:lower())
    end
  elseif style == 'PascalCase' or style == 'camelCase' then
    local i = 1
    local len = #str
    local word_idx = 0
    while i <= len do
      local char = str:sub(i, i)
      if char:match('%u') then
        word_idx = word_idx + 1
        local j = i + 1
        while j <= len and str:sub(j, j):match('%u') do
          j = j + 1
        end
        if j > i + 1 and j <= len and str:sub(j, j):match('%l') then
          table.insert(words, str:sub(i, j - 2):lower())
          acronyms[word_idx] = true
          i = j - 1
        elseif j > i + 1 then
          table.insert(words, str:sub(i, j - 1):lower())
          acronyms[word_idx] = true
          i = j
        else
          local k = j
          while k <= len and str:sub(k, k):match('%l') do
            k = k + 1
          end
          table.insert(words, str:sub(i, k - 1):lower())
          i = k
        end
      else
        word_idx = word_idx + 1
        local j = i
        while j <= len and str:sub(j, j):match('%l') do
          j = j + 1
        end
        if j > i then
          table.insert(words, str:sub(i, j - 1):lower())
        end
        i = j
      end
    end
  end

  return { words = words, acronyms = acronyms }
end

function M.to_camel_case(words, acronyms)
  acronyms = acronyms or {}
  local result = {}
  for i, word in ipairs(words) do
    if i == 1 then
      table.insert(result, word:lower())
    else
      if acronyms[i] then
        table.insert(result, word:upper())
      else
        table.insert(result, word:sub(1, 1):upper() .. word:sub(2):lower())
      end
    end
  end
  return table.concat(result)
end

function M.to_pascal_case(words, acronyms)
  acronyms = acronyms or {}
  local result = {}
  for i, word in ipairs(words) do
    if acronyms[i] then
      table.insert(result, word:upper())
    else
      table.insert(result, word:sub(1, 1):upper() .. word:sub(2):lower())
    end
  end
  return table.concat(result)
end

function M.to_snake_case(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:lower())
  end
  return table.concat(result, '_')
end

function M.to_screaming_snake(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:upper())
  end
  return table.concat(result, '_')
end

function M.to_kebab_case(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:lower())
  end
  return table.concat(result, '-')
end

function M.to_title_case(words, acronyms)
  acronyms = acronyms or {}
  local result = {}
  for i, word in ipairs(words) do
    if acronyms[i] then
      table.insert(result, word:upper())
    else
      table.insert(result, word:sub(1, 1):upper() .. word:sub(2):lower())
    end
  end
  return table.concat(result, ' ')
end

function M.to_lowercase(words)
  local result = {}
  for _, word in ipairs(words) do
    table.insert(result, word:lower())
  end
  return table.concat(result, ' ')
end

function M.generate_variants(words, acronyms)
  return {
    { style = 'camelCase', value = M.to_camel_case(words, acronyms) },
    { style = 'PascalCase', value = M.to_pascal_case(words, acronyms) },
    { style = 'snake_case', value = M.to_snake_case(words) },
    { style = 'SCREAMING_SNAKE', value = M.to_screaming_snake(words) },
    { style = 'kebab-case', value = M.to_kebab_case(words) },
    { style = 'Title Case', value = M.to_title_case(words, acronyms) },
    { style = 'lowercase', value = M.to_lowercase(words) },
  }
end

return M
