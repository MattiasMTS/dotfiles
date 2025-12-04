---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl", "templ", "tmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
  settings = {
    gopls = {
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      analyses = {
        ST1000 = false, -- ignore "docs required in pkg"
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      gofumpt = false, -- replaced with conform
      usePlaceholders = true,
      staticcheck = true,
      completeUnimported = true,
      vulncheck = "imports",
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      semanticTokens = true,
      templateExtensions = { "templ", "tmpl" },
      analysisProgressReporting = true,
    },
  },
}
