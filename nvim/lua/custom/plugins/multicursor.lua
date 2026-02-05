return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Add or skip cursor above/below the main cursor.
    set({"n", "x"}, "<up>", function() mc.lineAddCursor(-1) end)
    set({"n", "x"}, "<down>", function() mc.lineAddCursor(1) end)
    set({"n", "x"}, "<leader><up>", function() mc.lineSkipCursor(-1) end)
    set({"n", "x"}, "<leader><down>", function() mc.lineSkipCursor(1) end)

    -- Add or skip adding a new cursor by matching word/selection
    set({"n", "x"}, "<leader>n", function() mc.matchAddCursor(1) end, { desc = "Add cursor - (n)ext match" })
    set({"n", "x"}, "<leader>s", function() mc.matchSkipCursor(1) end, { desc = "Add cursor - (s)kip next match" })
    set({"n", "x"}, "<leader>N", function() mc.matchAddCursor(-1) end, { desc = "Add cursor - previous match" })
    set({"n", "x"}, "<leader>S", function() mc.matchSkipCursor(-1) end, { desc = "Add cursor - (s)kip previous match" })

    -- Add a cursor for all matches of cursor word/selection in the document.
    set({"n", "x"}, "<leader>A", mc.matchAllAddCursors, { desc = "Add cursor - (a)ll matches" })

    -- Append/insert for each line of visual selections.
    -- Similar to block selection insertion.
    set("x", "I", mc.insertVisual)
    set("x", "A", mc.appendVisual)

    -- Disable and enable cursors.
    set({"n", "x"}, "<c-q>", mc.toggleCursor)

    -- Add a cursor and jump to the next/previous search result.
    set("n", "<leader>/n", function() mc.searchAddCursor(1) end, { desc = "Add cursor - (n)ext search match" })
    set("n", "<leader>/N", function() mc.searchAddCursor(-1) end)

    -- Jump to the next/previous search result without adding a cursor.
    set("n", "<leader>/s", function() mc.searchSkipCursor(1) end, { desc = "Add cursor - skip next search match" })
    set("n", "<leader>/S", function() mc.searchSkipCursor(-1) end)

    -- Add a cursor to every search result in the buffer.
    set("n", "<leader>/A", mc.searchAllAddCursors, { desc = "Add cursor - all search matches" })

    -- Mappings defined in a keymap layer only apply when there are
    -- multiple cursors. This lets you have overlapping mappings.
    mc.addKeymapLayer(function(layerSet)

      -- Select a different cursor as the main one.
      layerSet({"n", "x"}, "<left>", mc.prevCursor)
      layerSet({"n", "x"}, "<right>", mc.nextCursor)

      -- Delete the main cursor.
      layerSet({"n", "x"}, "<leader>x", mc.deleteCursor)

      -- Enable and clear cursors using escape.
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- Customize how cursors look.
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn"})
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { reverse = true })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn"})
  end
}
