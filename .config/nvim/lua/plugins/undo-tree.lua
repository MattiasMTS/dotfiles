return {
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
