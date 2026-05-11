return {
  {
    dir = vim.fn.expand("$VIMRUNTIME/pack/dist/opt/nvim.undotree"),
    keys = {
      { "<leader>u", "<Cmd>Undotree<CR>", desc = "Toggle Undotree" },
    },
  },
  {
    dir = vim.fn.expand("$VIMRUNTIME/pack/dist/opt/nvim.difftool"),
    cmd = { "DiffTool", "DiffToolGit" },
    keys = {
      { "<leader>dD", "<Cmd>DiffToolGit main...<CR>", desc = "DiffTool vs main (PR-style)", silent = true },
    },
    config = function()
      local ZERO = "0000000000000000000000000000000000000000"

      vim.api.nvim_create_user_command("DiffToolGit", function(opts)
        local has_augroup = pcall(vim.api.nvim_get_autocmds, { group = "nvim.difftool.events" })
        if has_augroup then
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
              pcall(vim.api.nvim_win_close, win, false)
            end
          end
          pcall(vim.cmd, "cclose")
          return
        end

        local args = opts.args ~= "" and opts.args or "HEAD"

        local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
        if vim.v.shell_error ~= 0 or not root or root == "" then
          vim.notify("Not in a git repo", vim.log.levels.ERROR)
          return
        end

        local raw = vim.fn.systemlist({ "git", "-C", root, "diff", "--raw", "--no-abbrev", "--no-renames", args })
        if vim.v.shell_error ~= 0 then
          vim.notify("git diff failed for: " .. args, vim.log.levels.ERROR)
          return
        end
        if #raw == 0 then
          vim.notify("No changes for: " .. args, vim.log.levels.INFO)
          return
        end

        local left = vim.fn.tempname()
        local right = vim.fn.tempname()
        vim.fn.mkdir(left, "p")
        vim.fn.mkdir(right, "p")

        for _, line in ipairs(raw) do
          local from_hash, to_hash, rel = line:match("^:%S+%s+%S+%s+(%S+)%s+(%S+)%s+%S+\t(.+)$")
          if rel then
            local lpath = left .. "/" .. rel
            local rpath = right .. "/" .. rel
            vim.fn.mkdir(vim.fs.dirname(lpath), "p")
            vim.fn.mkdir(vim.fs.dirname(rpath), "p")

            if from_hash ~= ZERO then
              vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " cat-file -p " .. from_hash .. " > " .. vim.fn.shellescape(lpath))
            end

            if to_hash == ZERO then
              local src = root .. "/" .. rel
              if vim.fn.filereadable(src) == 1 then
                vim.fn.system({ "cp", src, rpath })
              end
            else
              vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " cat-file -p " .. to_hash .. " > " .. vim.fn.shellescape(rpath))
            end
          end
        end

        vim.cmd.packadd("nvim.difftool")
        require("difftool").open(left, right)

        vim.schedule(function()
          vim.schedule(function()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
                local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
                if vim.startswith(name, left .. "/") then
                  vim.wo[win].winhighlight = "DiffChange:DiffToolDelLine,DiffText:DiffToolDelText"
                elseif vim.startswith(name, right .. "/") then
                  vim.wo[win].winhighlight = "DiffChange:DiffToolAddLine,DiffText:DiffToolAddText"
                end
              end
            end
          end)
        end)
      end, { nargs = "?" })
    end,
  },
}
