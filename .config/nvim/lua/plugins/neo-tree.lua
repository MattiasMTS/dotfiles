return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = true,
    branch = "v3.x",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = {
      window = {
        position = "left",
        width = 40,
        mappings = {
          ["l"] = "open",
          ["-"] = "navigate_up",
        },
      },
      filesystem = {
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true,
        },
        follow_current_file = {
          enabled = true,
        },
      },
      default_component_configs = {
        icon = {
          provider = function(icon, node)
            local mini = require("mini.icons")

            local ok, text = pcall(mini.get, node.type, node.name)
            if not ok then
              return
            end

            icon.text = text
          end,
        },
      },
    },
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true })
        end,
        desc = "Explorer NeoTree (Root Dir)",
      },
    },
  },
  {
    "mbbill/undotree",
    enabled = true,
    cmd = { "UndotreeToggle", "UndotreeFocus", "UndotreeHide", "UndotreeShow", "UndotreePersistUndo" },
    opts = {},
    keys = {
      {
        "<leader>u",
        "<Cmd>UndotreeToggle<CR>",
        desc = "Toggle Undotree",
      },
    },
  },
}
