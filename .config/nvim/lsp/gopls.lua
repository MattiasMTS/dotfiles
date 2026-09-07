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

-- Shared daemon, owned by nvim rather than by gopls' `-remote=auto`:
--   * `auto` derives the socket name from `go tool buildid`, which Go >= 1.26
--     builds on demand: 3-4s per nvim start, ~90s after a build-cache wipe.
--   * `auto` also keys the daemon only on the gopls binary, so the first nvim's
--     environment (PATH `go`, GOTOOLCHAIN) is frozen for every later session;
--     after a repo bumps its go version every new view fails with
--     "go.work requires go >= X (running go Y)".
-- So key the socket on (gopls binary, go toolchain) and spawn the daemon from
-- this nvim, inheriting this devshell's env. A toolchain bump lands on a fresh
-- socket, so the stale daemon is simply never dialled again and exits after
-- its idle timeout. Cost: ~1-2 GB per live worktree view (GOMEMLIMIT below); idle 168h so a
-- weekend does not go cold. Kill by hand: `pkill -f 'gopls serve -listen=unix'`
-- (gopls 0.23 has no `remote stop`); the next nvim respawns it.
local function daemon_socket()
  local gopls_real = vim.uv.fs_realpath(vim.fn.exepath(gopls_bin)) or gopls_bin
  local go = vim.fn.exepath("go")
  local go_real = go ~= "" and (vim.uv.fs_realpath(go) or go) or "no-go"
  local key = vim.fn.sha256(gopls_real .. "\n" .. go_real):sub(1, 12)
  -- $TMPDIR, not stdpath("run"): unix socket paths cap at 104 bytes on macOS.
  return vim.uv.os_tmpdir() .. "/gopls-" .. key .. ".sock"
end

--- True when something is listening on `sock`. A socket file whose daemon has
--- died (crash, reboot) is removed so the spawn below can bind it.
local function daemon_alive(sock)
  if not vim.uv.fs_stat(sock) then
    return false
  end
  local pipe = vim.uv.new_pipe(false)
  local done, ok = false, false
  pipe:connect(sock, function(err)
    ok, done = err == nil, true
    pipe:close()
  end)
  vim.wait(500, function()
    return done
  end, 10)
  if not ok then
    os.remove(sock)
  end
  return ok
end

local function ensure_daemon(sock)
  if daemon_alive(sock) then
    return
  end
  vim.system({ gopls_bin, "serve", "-listen=unix;" .. sock, "-listen.timeout=168h" }, {
    detach = true,
    stdin = false,
    stdout = false,
    stderr = false,
    -- Dropped views are not returned to the OS by default: measured 14.5 GB
    -- after four worktree sessions. A soft limit makes the GC give it back.
    env = { GOMEMLIMIT = "10GiB" },
  })
  -- The forwarder retries the dial for ~5s while the daemon binds.
end

-- `cmd` is a function so the daemon is only probed/spawned when a Go buffer
-- actually starts a client; this file is loaded eagerly by every nvim start.
local gopls_cmd
if vim.env.GOPLS_TRACE == "1" then
  -- trace mode: direct (no daemon) so the log captures everything
  gopls_cmd = { gopls_bin, "-rpc.trace", "-logfile=/tmp/gopls.log" }
else
  gopls_cmd = function(dispatchers, config)
    local sock = daemon_socket()
    ensure_daemon(sock)
    return vim.lsp.rpc.start({ gopls_bin, "-remote=unix;" .. sock }, dispatchers, {
      cwd = config.cmd_cwd,
      env = config.cmd_env,
    })
  end
end

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
