return {
  {
    "MattiasMTS/manicule.nvim",
    dev = true,
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "ManiculeAdd", "ManiculeList", "ManiculeSend" },
    keys = {
      { "<leader>ma", "<Plug>(manicule-add)", mode = { "n", "x" }, desc = "Manicule: add comment" },
      { "<leader>ml", "<Plug>(manicule-list)", desc = "Manicule: list comments" },
      { "<leader>ms", "<cmd>ManiculeSend<CR>", desc = "Manicule: send comments" },
      { "<leader>mc", "<cmd>ManiculeSend cmux<CR>", desc = "Manicule: send to cmux agent" },
    },
    opts = {},
    config = function(_, opts)
      require("manicule").setup(opts)

      local cmux = require("utils.cmux")
      local manicule_uri = require("manicule.uri")

      local function display_path(c)
        local abs = manicule_uri.to_path(c.uri)
        if abs and c.project_root then
          local rel = vim.fs.relpath(c.project_root, abs)
          if rel then
            return rel
          end
        end
        return abs or c.uri
      end

      ---Format one record as a markdown section line (for the review file).
      local function format_record(c)
        local s = c.range.start[1] + 1
        local e = c.range["end_"] and (c.range["end_"][1] + 1) or s
        local rng = (e ~= s) and (s .. "-" .. e) or tostring(s)
        return display_path(c), rng, c.body or ""
      end

      local function build_review_text(comments)
        local parts = {
          ("Manicule review (%d comment%s):"):format(#comments, #comments == 1 and "" or "s"),
          "",
        }
        for _, c in ipairs(comments) do
          local path, rng, body = format_record(c)
          table.insert(parts, ("## %s:%s"):format(path, rng))
          for _, bl in ipairs(vim.split(body, "\n", { plain = true })) do
            table.insert(parts, bl)
          end
          table.insert(parts, "")
        end
        return table.concat(parts, "\n")
      end

      local function ctx_surface(ctx)
        ctx = ctx or {}
        return ctx.surface or ctx.surface_ref or ctx.agent_id
      end

      local function pick_surface(cb)
        local surfaces, err = cmux.list_agent_surfaces()
        if not surfaces or #surfaces == 0 then
          cb(nil, err or "no cmux agent surfaces found")
          return
        end
        if #surfaces == 1 then
          cb(surfaces[1])
          return
        end
        vim.ui.select(surfaces, {
          prompt = "cmux: send review to",
          format_item = cmux.surface_label,
        }, function(surface)
          if not surface then
            cb(nil, "cancelled")
            return
          end
          cb(surface)
        end)
      end

      local function send_to_surface(surface, comments, cb)
        local surface_ref = cmux.surface_ref(surface)
        if not surface_ref or surface_ref == "" then
          cb(false, "cmux target has no surface ref")
          return
        end

        local text = build_review_text(comments)
        local ok, send_err = cmux.send_text(surface_ref, text)
        if not ok then
          return cb(false, send_err or "cmux send failed")
        end

        local label = type(surface) == "table" and cmux.surface_label(surface) or tostring(surface_ref)
        local key_ok = cmux.send_key(surface_ref, "enter")
        if not key_ok then
          vim.notify("Review sent to " .. label .. " — press Enter in that cmux pane to submit", vim.log.levels.WARN)
          return cb(false, "text landed but submit failed — press Enter in the cmux pane manually")
        end
        vim.notify("Review sent to " .. label, vim.log.levels.INFO)
        cb(true)
      end

      require("manicule").register_sink({
        name = "cmux",
        label = "cmux agent",
        description = "send review to a running cmux agent",
        clear_on_success = true,
        validate = function(ctx)
          if ctx_surface(ctx) then
            return true
          end
          local surfaces, err = cmux.list_agent_surfaces()
          if not surfaces or #surfaces == 0 then
            return false, err or "no cmux agent surfaces found"
          end
          return true
        end,
        format = function(c)
          local path, rng, body = format_record(c)
          return ("%s:%s: %s"):format(path, rng, body)
        end,
        send = function(comments, ctx, cb)
          local target = ctx_surface(ctx)
          if target then
            send_to_surface(target, comments, cb)
            return
          end

          pick_surface(function(surface, err)
            if not surface then
              return cb(false, err or "cancelled")
            end
            send_to_surface(surface, comments, cb)
          end)
        end,
      })
    end,
  },
}
