---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gosum", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
  settings = {
    gopls = {
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
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
        modernize = true,
        yield = true,
        waitgroup = true,
      },
      gofumpt = false, -- replaced with conform
      usePlaceholders = true,
      staticcheck = false, -- managed by nvim-lint
      completeUnimported = true,
      vulncheck = "Imports",
      hints = {
        -- assignVariableTypes = false, -- Reduced for performance
        compositeLiteralFields = false,
        compositeLiteralTypes = false,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = false,
      },
      semanticTokens = true,
      templateExtensions = { "templ", "tmpl" },
      analysisProgressReporting = false, -- Reduced notification spam
      -- Performance tuning for large codebases
      diagnosticsDelay = "500ms",
      diagnosticsTrigger = "Edit",
      completionBudget = "200ms",
      symbolMatcher = "FastFuzzy",
      directoryFilters = {
        "-.git",
        "-.vscode",
        "-.idea",
        "-.vscode-test",
        "-node_modules",
        "-vendor",
        "-testdata",
        "-.cache",
      },
    },
  },
}
