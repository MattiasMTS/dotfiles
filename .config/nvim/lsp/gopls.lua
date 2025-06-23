---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl", "templ", "tmpl" },
  settings = {
    gopls = {
      gofumpt = false, -- managed by conform instead
      usePlaceholders = true,
      -- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
      hints = {
        parameterNames = true,
        assignVariableTypes = true,
        constantValues = true,
        compositeLiteralTypes = true,
        compositeLiteralFields = true,
        functionTypeParameters = true,
      },
      staticcheck = true,
      vulncheck = "imports",
      analysisProgressReporting = true,
      templateExtensions = { "templ", "tmpl" },
    },
  },
}
