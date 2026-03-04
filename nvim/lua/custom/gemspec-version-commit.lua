-- Gemspec version commit helper
-- Stages a modified gemspec and opens neogit commit with a pre-filled version bump message
-- Usage: <leader>gp after manually updating a gemspec version

local M = {}

local specifiers = {
  client = 'Client',
  common = 'Common',
  component = 'Component',
  core = 'Core',
  data = 'Data',
  http = 'Http',
  routes = 'Routes',
  schemas = 'Schemas',
  web = 'Web',
}

function M.parse_version_diff(diff_text)
  local old_version, new_version

  for line in diff_text:gmatch '[^\n]+' do
    local removed = line:match '^%-.*s%.version%s*=%s*"([%d%.]+)"'
    if removed then
      old_version = removed
    end

    local added = line:match '^%+.*s%.version%s*=%s*"([%d%.]+)"'
    if added then
      new_version = added
    end
  end

  return old_version, new_version
end

function M.detect_specifier(gemspec_path)
  local dir = gemspec_path:match '^(.+)/[^/]+%.gemspec$'
  if dir then
    local last_dir = dir:match '([^/]+)$'
    if last_dir and specifiers[last_dir] then
      return specifiers[last_dir]
    end
  end
  return nil
end

function M.format_message(specifier, old_version, new_version)
  if specifier then
    return specifier .. ' package version is increased from ' .. old_version .. ' to ' .. new_version
  else
    return 'Package version is increased from ' .. old_version .. ' to ' .. new_version
  end
end

function M.find_gemspec_and_diff()
  -- Check unstaged changes first
  local unstaged_files = vim.fn.systemlist 'git diff --name-only'
  for _, file in ipairs(unstaged_files) do
    if file:match '%.gemspec$' and not file:match '^gems/' then
      local diff = vim.fn.system('git diff -- ' .. vim.fn.shellescape(file))
      return file, diff, false
    end
  end

  -- Fall back to staged changes
  local staged_files = vim.fn.systemlist 'git diff --cached --name-only'
  for _, file in ipairs(staged_files) do
    if file:match '%.gemspec$' and not file:match '^gems/' then
      local diff = vim.fn.system('git diff --cached -- ' .. vim.fn.shellescape(file))
      return file, diff, true
    end
  end

  return nil, nil, nil
end

function M.commit_gemspec_version()
  local gemspec_path, diff, is_staged = M.find_gemspec_and_diff()

  if not gemspec_path then
    vim.notify('No modified gemspec found', vim.log.levels.WARN)
    return
  end

  local old_version, new_version = M.parse_version_diff(diff)
  if not old_version or not new_version then
    vim.notify('Could not parse version change from gemspec diff', vim.log.levels.WARN)
    return
  end

  local specifier = M.detect_specifier(gemspec_path)
  local message = M.format_message(specifier, old_version, new_version)

  local we_staged_it = not is_staged
  if we_staged_it then
    vim.fn.system('git add -- ' .. vim.fn.shellescape(gemspec_path))
  end

  local committed = false
  local augroup = vim.api.nvim_create_augroup('GemspecVersionCommit', { clear = true })

  vim.api.nvim_create_autocmd('User', {
    group = augroup,
    pattern = 'NeogitCommitComplete',
    once = true,
    callback = function()
      committed = true
    end,
  })

  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'gitcommit',
    once = true,
    callback = function()
      vim.api.nvim_buf_set_lines(0, 0, 0, false, { message })

      vim.api.nvim_create_autocmd('BufUnload', {
        group = augroup,
        buffer = 0,
        once = true,
        callback = function()
          vim.defer_fn(function()
            if not committed and we_staged_it then
              vim.fn.system('git reset HEAD -- ' .. vim.fn.shellescape(gemspec_path))
            end
            vim.api.nvim_create_augroup('GemspecVersionCommit', { clear = true })
          end, 200)
        end,
      })
    end,
  })

  require('neogit').action('commit', 'commit')()
end

vim.keymap.set('n', '<leader>gp', M.commit_gemspec_version, { desc = 'Commit gemspec version bump' })

return M
