-- Project Picker Module
-- Manages multiple projects from ~/wsgr/neuron

local M = {}

-- Configuration
M.config = {
  project_root = vim.fn.expand('~/wsgr/neuron'),
  max_depth = 1, -- How deep to search for projects
  recent_projects_file = vim.fn.stdpath('data') .. '/recent_projects.txt',
  max_recent = 20,
}

-- Get list of all projects
local function get_projects()
  local projects = {}
  local cmd = string.format('find %s -mindepth 1 -maxdepth %d -type d', M.config.project_root, M.config.max_depth)

  local handle = io.popen(cmd)
  if handle then
    for line in handle:lines() do
      table.insert(projects, line)
    end
    handle:close()
  end

  return projects
end
-- Find files in current project directory
function M.find_in_project()
  local cwd = vim.fn.getcwd(-1, -1) -- Get tab-local cwd
  require('telescope.builtin').find_files {
    cwd = cwd,
    prompt_title = 'Find in Project: ' .. vim.fn.fnamemodify(cwd, ':t'),
  }
end

-- Grep in current project directory
function M.grep_in_project()
  local cwd = vim.fn.getcwd(-1, -1) -- Get tab-local cwd
  require('telescope.builtin').live_grep {
    cwd = cwd,
    prompt_title = 'Grep in Project: ' .. vim.fn.fnamemodify(cwd, ':t'),
  }
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M

