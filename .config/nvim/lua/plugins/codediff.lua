--- Find the tmux pane running Claude CLI.
---@return string|nil pane_id The tmux pane ID (e.g. "%3"), or nil if not found
local function find_claude_tmux_pane()
  if not vim.env.TMUX then
    return nil
  end
  local result = vim.fn.system("tmux list-panes -s -F '#{pane_id} #{pane_current_command}'")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  for line in result:gmatch("[^\n]+") do
    local pane_id, cmd = line:match("^(%%[%d]+)%s+(.+)$")
    if pane_id and cmd and cmd:lower():find("claude") then
      return pane_id
    end
  end
  return nil
end

--- Send text via tmux send-keys.
---@param text string
---@param pane_id string
---@return boolean
local function send_via_tmux(text, pane_id)
  vim.fn.system({ "tmux", "send-keys", "-t", pane_id, "-l", text })
  if vim.v.shell_error ~= 0 then
    return false
  end
  vim.fn.system({ "tmux", "send-keys", "-t", pane_id, "Enter" })
  return true
end

return {
  {
    "esmuellert/codediff.nvim",
    dev = true,
    cmd = "CodeDiff",
    opts = {
      explorer = {
        view_mode = "tree", -- tree | list
        initial_focus = "modified",
      },
      history = {
        initial_focus = "modified",
      },
      diff = {
        disable_inlay_hints = true,
        max_computation_time_ms = 5000,
        layout = "inline",
      },
      keymaps = {
        view = {
          next_hunk = "]c",
          prev_hunk = "[c",
          next_file = "<Tab>",
          prev_file = "<S-Tab>",
        },
        explorer = {
          select = "<CR>",
          hover = "K",
          refresh = "R",
        },
      },
      comments = {
        ui = {
          width = 72,
          height = 6,
          editor_mode = "insert",
          submit_keys = { "<CR>" },
          cancel_keys = { "q" },
          opacity = 0,
        },
      },
    },
    config = function(_, opts)
      require("codediff").setup(opts)
      local cd_comments = require("codediff.ui.comments")

      cd_comments.add_sink({
        name = "agent",
        enabled = function()
          -- amp.nvim connected?
          local ok, amp = pcall(require, "amp")
          if ok and amp.state.connected then
            return true
          end
          -- claude CLI in a tmux pane?
          return find_claude_tmux_pane() ~= nil
        end,
        handler = function(comments, context, done)
          local payload = cd_comments.format(comments, context)

          -- 1. amp.nvim: direct message API
          local ok, amp_msg = pcall(require, "amp.message")
          if ok and require("amp").state.connected then
            local sent = amp_msg.send_message(payload)
            done(sent, sent and nil or "amp.nvim send failed")
            return
          end

          -- 2. claudecode: tmux send-keys to Claude pane
          local pane_id = find_claude_tmux_pane()
          if pane_id and send_via_tmux(payload, pane_id) then
            done(true)
            return
          end

          done(false, "no agent connected")
        end,
      })
    end,
    keys = {
      { "<leader>do", ":CodeDiff main...<CR>", desc = "Toggle CodeDiff against main", silent = true },
      { "<leader>dh", ":CodeDiff history %<CR>", desc = "File history", silent = true },
      { "<leader>dH", ":CodeDiff history<CR>", desc = "Repo history", silent = true },
    },
  },
}
