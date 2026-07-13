local gopls_cmd = vim.env.GOPLS_TRACE == "1" and { "gopls", "-rpc.trace", "-logfile=/tmp/gopls.log" } or { "gopls" }

local function disable_semantic_tokens(client)
  client.server_capabilities.semanticTokensProvider = nil
end

local function gopls_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.semanticTokens = nil
  capabilities.workspace.semanticTokens = nil
  return capabilities
end

---@type vim.lsp.Config
return {
  cmd = gopls_cmd,
  capabilities = gopls_capabilities(),
  on_init = disable_semantic_tokens,
  filetypes = { "go", "gomod", "gowork", "gosum", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
  settings = {
    gopls = {
      buildFlags = { "-tags=unit,emulator,integration" },
      codelenses = {
        gc_details = false,
        generate = false,
        regenerate_cgo = false,
        run_govulncheck = false,
        test = false,
        tidy = false,
        upgrade_dependency = false,
        vendor = false,
      },
      analyses = {
        ST1000 = false, -- ignore "docs required in pkg"
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        yield = true,
        waitgroup = true,
      },
      gofumpt = false, -- replaced with conform
      usePlaceholders = false, -- VS Code default
      matcher = "CaseInsensitive",
      staticcheck = false, -- managed by nvim-lint
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
      -- Tree-sitter handles Go highlighting; keep semantic token work out of gopls.
      semanticTokens = false,
      templateExtensions = { "templ", "tmpl" },
      analysisProgressReporting = true, -- VS Code default
      diagnosticsDelay = "1s", -- VS Code default
      diagnosticsTrigger = "Edit", -- gopls default; keeps diagnostics fresh after generated files change.
      symbolMatcher = "FastFuzzy",
      directoryFilters = {
        "-**/.agents",
        "-**/.gotmp",
        "-**/node_modules",
        "-**/vendor",
        "-**/.git",
        "-**/.direnv",
      },
    },
  },
}
