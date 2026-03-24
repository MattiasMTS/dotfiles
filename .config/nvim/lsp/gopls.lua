---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gosum", "gotmpl" },
  root_markers = { "go.mod", ".git" },
  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
  settings = {
    gopls = {
      -- VS Code defaults: mostly let gopls use its own defaults
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
        modernize = true,
        yield = true,
        waitgroup = true,
      },
      env = { GOWORK = "off" }, -- disable go.work to avoid loading all modules in monorepos
      gofumpt = false, -- replaced with conform
      usePlaceholders = false, -- VS Code default
      staticcheck = false, -- managed by nvim-lint
      completeUnimported = true, -- gopls default
      vulncheck = "Off", -- VS Code default is "Prompt", but "Off" is lighter
      hints = {
        assignVariableTypes = false,
        compositeLiteralFields = false,
        compositeLiteralTypes = false,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = false,
      },
      semanticTokens = true,
      templateExtensions = { "templ", "tmpl" },
      analysisProgressReporting = true, -- VS Code default
      diagnosticsDelay = "1s", -- VS Code default
      diagnosticsTrigger = "Edit", -- VS Code default
      symbolMatcher = "FastFuzzy",
      directoryFilters = {
        "-**/node_modules",
        "-**/vendor",
        "-**/.git",
        "-**/.direnv",
      },
    },
  },
}
