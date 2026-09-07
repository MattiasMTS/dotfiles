-- gopls registers a watcher for <workspace>/vendor even when it doesn't exist;
-- nvim's watcher then toasts "watch.watch: ENOENT" every session instead of
-- skipping it (nvim#28058, golang/go#67995). Skip watching missing paths.
pcall(function()
  local watch = require("vim._watch")
  local orig_watch = watch.watch
  watch.watch = function(path, opts, callback)
    if not vim.uv.fs_stat(path) then
      return function() end -- no-op cancel; nothing to watch
    end
    return orig_watch(path, opts, callback)
  end
end)

-- Prefer the home-profile gopls (stable nix-darwin path) over whatever a repo
-- devshell puts on PATH: the daemon re-execs the binary that first starts it
-- and the socket is shared, so a devshell's older gopls would otherwise
-- become the daemon for every session (lovable pins 0.21.1).
local gopls_bin = "/etc/profiles/per-user/" .. (vim.env.USER or "") .. "/bin/gopls"
if vim.fn.executable(gopls_bin) ~= 1 then
  gopls_bin = "gopls"
end

-- Shared daemon (`-remote=auto`): every nvim attaches to one warm gopls, so
-- reopening a worktree whose view is still alive is instant; a new worktree
-- is always a cold load (~70s here, type-check cache keys include paths).
-- Idle timeout 168h so a weekend does not go cold.
--
-- Known costs, accepted for staying on the stock setup:
--   * the forwarder runs `go tool buildid` to name the socket; Go >= 1.26
--     builds that tool on demand: ~3s per nvim start, ~90s after `make clean`.
--   * the daemon keeps the environment of the nvim that spawned it, including
--     PATH `go`. After a repo bumps its go version every new view fails with
--     "go.work requires go >= X (running go Y)" while nvim looks attached.
--     Fix by hand: `pkill -f 'gopls serve -listen'`, reopen nvim from inside
--     the devshell. (gopls 0.23 has no `remote stop`.)
local gopls_cmd = vim.env.GOPLS_TRACE == "1" and { gopls_bin, "-rpc.trace", "-logfile=/tmp/gopls.log" } -- trace mode: direct (no daemon) so the log captures everything
  or { gopls_bin, "-remote=auto", "-remote.listen.timeout=168h" }

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
