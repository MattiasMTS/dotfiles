return {
  {
    "Piotr1215/presenterm.nvim",
    build = false, -- built via nix
    -- cmd = "Presenterm",
    opts = {
      default_keybindings = true,
      picker = { provider = "fzf" },
      preview = {
        command = "presenterm -xX",
        presentation_preview_sync = true,
      },
    },
  },
}
