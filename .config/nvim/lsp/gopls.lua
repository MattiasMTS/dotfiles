---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  settings = {
    -- env = { GOEXPERIMENT = "rangefunc" },
    formatting = { gofumpt = false }, -- managed by conform
    -- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
    hints = {},
  },
}
