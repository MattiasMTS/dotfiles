---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl", "templ", "tmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
  settings = {
    gopls = {
      gofumpt = false, -- replaced with conform
      usePlaceholders = true,
      staticcheck = true,
      vulncheck = "imports",
      hints = {
        parameterNames = true,
        assignVariableTypes = true,
        constantValues = true,
        compositeLiteralTypes = true,
        compositeLiteralFields = true,
        functionTypeParameters = true,
        rangeVariableTypes = false,
      },
      semanticTokens = true,
      templateExtensions = { "templ", "tmpl" },
      analysisProgressReporting = true,
    },
  },
}
