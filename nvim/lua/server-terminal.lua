-- Server terminal for long-running processes (web servers, eventide components)
-- Separate from the main FTerm floating terminal

local M = {}

local server_term = nil
local current_variant = nil -- "default" or "alternate"

local function cleanup_server()
  local pid = vim.g.server_terminal_pid
  if pid then
    -- Recursively kill all descendants (children, grandchildren, etc.)
    local kill_script = [[
      kill_tree() {
        local pid=$1
        local children=$(pgrep -P $pid 2>/dev/null)
        for child in $children; do
          kill_tree $child
        done
        kill -TERM $pid 2>/dev/null
      }
      kill_tree ]] .. pid
    vim.fn.system { 'bash', '-c', kill_script }
  end
  vim.g.server_terminal_pid = nil
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function detect_project_type()
  local cwd = vim.fn.getcwd()
  if file_exists(cwd .. '/script/rails') then
    return 'web'
  elseif file_exists(cwd .. '/test/start-component.sh') then
    return 'component'
  else
    return nil
  end
end

local function get_command(project_type, variant)
  local commands = {
    web = {
      default = 'nr',
      alternate = 'nrp',
    },
    component = {
      default = 'cmdb && ./test/start-component.sh',
      alternate = 'cmdb && ./component/script/start',
    },
  }
  return commands[project_type][variant]
end

local function capture_pid()
  if server_term and server_term.buf and vim.api.nvim_buf_is_valid(server_term.buf) then
    local ok, job_id = pcall(vim.api.nvim_buf_get_var, server_term.buf, 'terminal_job_id')
    if ok and job_id then
      vim.g.server_terminal_pid = vim.fn.jobpid(job_id)
    end
  end
end

local function create_server_term(cmd)
  local FTerm = require 'FTerm'
  server_term = FTerm:new {
    cmd = { 'zsh', '-ic', cmd },
    dimensions = {
      height = 0.9,
      width = 0.9,
    },
  }
  return server_term
end

local function start_server_with_cmd(cmd, variant)
  if server_term then
    cleanup_server()
    server_term:close(true)
  end
  current_variant = variant
  server_term = create_server_term(cmd)
  server_term:toggle()
  vim.defer_fn(capture_pid, 100)
end

local function prompt_for_command(variant)
  local Input = require 'nui.input'

  local input = Input({
    position = '50%',
    size = { width = 40 },
    border = {
      style = 'rounded',
      text = {
        top = ' Server Command ',
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = 'Normal:Normal,FloatBorder:Normal',
    },
  }, {
    prompt = '> ',
    on_submit = function(value)
      if value and value ~= '' then
        start_server_with_cmd(value, variant)
      end
    end,
  })

  input:mount()

  input:map('n', '<Esc>', function()
    input:unmount()
  end, { noremap = true })

  input:map('i', '<C-c>', function()
    input:unmount()
  end, { noremap = true })
end

function M.toggle(variant)
  local project_type = detect_project_type()

  if not project_type then
    prompt_for_command(variant)
    return
  end

  local cmd = get_command(project_type, variant)

  if not server_term then
    current_variant = variant
    server_term = create_server_term(cmd)
    server_term:toggle()
    vim.defer_fn(capture_pid, 100)
    return
  end

  if current_variant == variant then
    server_term:toggle()
    return
  end

  start_server_with_cmd(cmd, variant)
end

function M.cleanup()
  cleanup_server()
end

return M
