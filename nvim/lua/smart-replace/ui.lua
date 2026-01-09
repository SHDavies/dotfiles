local Input = require('nui.input')

local M = {}

function M.prompt_replacement(source, on_submit)
  local input = Input({
    position = '50%',
    size = { width = 40 },
    border = {
      style = 'rounded',
      text = {
        top = ' Replace ' .. source .. ' ',
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = 'Normal:Normal,FloatBorder:Normal',
    },
  }, {
    prompt = '> ',
    default_value = source,
    on_submit = function(value)
      if value and value ~= '' then
        on_submit(value)
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

return M
