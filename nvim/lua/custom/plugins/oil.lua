local prompt_save = function()
  local oil = require 'oil'
  local Menu = require 'nui.menu'

  local popup_options = {
    position = {
      row = '20%',
      col = '50%',
    },
    size = {
      width = 20,
      height = 4,
    },
    border = {
      style = 'rounded',
      padding = {
        left = 1,
      },
      text = {
        top = ' Save changes? ',
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = 'Normal:Normal',
    },
  }

  local menu = Menu(popup_options, {
    lines = {
      Menu.item('Save', { value = 'save' }),
      Menu.item('Confirm', { value = 'confirm' }),
      Menu.item('Discard', { value = 'discard' }),
      Menu.item('Cancel', { value = 'cancel' }),
    },
    max_width = 20,
    keymap = {
      focus_next = { 'j' },
      focus_prev = { 'k' },
      close = { '<Esc>' },
      submit = { '<CR>' },
    },
    on_submit = function(item)
      if item.value == 'save' then
        oil.save({ confirm = false }, function(err)
          if not err then
            oil.close()
          end
        end)
      elseif item.value == 'confirm' then
        oil.save({ confirm = true }, function(err)
          if not err then
            oil.close()
          end
        end)
      elseif item.value == 'discard' then
        oil.discard_all_changes()
        oil.close()
      end
    end,
  })

  menu:mount()
end

return {
  'stevearc/oil.nvim',
  opts = {
    skip_confirm_for_simple_edits = true,
    keymaps = {
      ['<C-s>'] = false,
      ['q'] = {
        callback = function()
          local oil = require 'oil'

          if vim.bo.modified then
            prompt_save()
            -- vim.ui.select({ 'Save', 'Discard', 'Cancel' }, {
            --   prompt = 'You have unsaved changes',
            -- }, function(choice)
            --   if choice == 'Save' then
            --     oil.save({}, function(err)
            --       if not err then
            --         oil.close()
            --       end
            --     end)
            --   elseif choice == 'Discard' then
            --     oil.discard_all_changes()
            --     oil.close()
            --   end
            -- end)
          else
            oil.close()
          end
        end,
        desc = 'Close oil with save prompt',
      },
    },
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name)
        return name == '.git' or name == '.DS_Store'
      end,
    },
    float = {
      padding = 8,
      max_width = 0.8,
      max_height = 0.9,
      border = 'rounded',
      preview_split = 'auto',
    },
    confirmation = {
      border = 'single',
    },
  },
  dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
  lazy = false,
  keys = {
    { '-', '<cmd>Oil --float<cr>', desc = 'Open parent directory' },
  },
}
