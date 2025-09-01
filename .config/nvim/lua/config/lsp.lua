local methods = vim.lsp.protocol.Methods

--- Sets up LSP keymaps and autocommands for the given buffer.
---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
  local function map(lhs, rhs, desc, mode)
    mode = mode or "n"
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
  end

  -- conform to upstream LSP keymaps defined in:
  -- https://neovim.io/doc/user/lsp.html#lsp-defaults

  -- grr gra grn gri i_CTRL-S These GLOBAL keymaps are created unconditionally when Nvim starts:
  -- "grn" is mapped in Normal mode to vim.lsp.buf.rename()
  -- "gra" is mapped in Normal and Visual mode to vim.lsp.buf.code_action()
  -- "grr" is mapped in Normal mode to vim.lsp.buf.references()
  -- "gri" is mapped in Normal mode to vim.lsp.buf.implementation()
  -- "gO" is mapped in Normal mode to vim.lsp.buf.document_symbol()
  -- CTRL-S is mapped in Insert mode to vim.lsp.buf.signature_help()

  map("gra", "<cmd>FzfLua lsp_code_actions silent=true<cr>", "vim.lsp.buf.code_action()", { "n", "x" })
  map("grr", "<cmd>FzfLua lsp_references<cr>", "vim.lsp.buf.references()")
  map("grt", "<cmd>FzfLua lsp_typedefs<cr>", "Go to type definition")
  map("gri", "<cmd>FzfLua lsp_implementations<cr>", "Go to implementation")
  map("grs", "<cmd>FzfLua lsp_document_symbols<cr>", "Document symbols")
  map("gro", vim.diagnostic.open_float, "Open Line Diagnostics")
  map("grw", "<cmd>FzfLua lsp_workspace_diagnostics<cr>", "Workspace diagnostics") -- TODO: should checkout trouble.nvim

  -- stylua: ignore start
  map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
  map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
  map("[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end, "Previous error")
  map("]e", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end, "Next error")
  -- stylua: ignore end

  if client:supports_method(methods.textDocument_definition) then
    map("grd", function()
      require("fzf-lua").lsp_definitions({ jump1 = true })
    end, "Go to definition")

    map("grD", function()
      require("fzf-lua").lsp_definitions({ jump1 = false })
    end, "Peek definition")
  end

  if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
    map("<leader>th", function()
      vim.g.inlay_hints = not vim.g.inlay_hints
      vim.lsp.inlay_hint.enable(vim.g.inlay_hints, { bufnr = bufnr })
      vim.notify("[Inlay Hints] " .. (vim.g.inlay_hints and "enabled" or "disabled"))
    end, "[T]oggle Inlay [H]ints")

    vim.lsp.inlay_hint.enable(vim.g.inlay_hints, { bufnr = bufnr })
  end

  if client:supports_method(methods.textDocument_documentHighlight) then
    local under_cursor_highlights_group = vim.api.nvim_create_augroup("cursor_highlights", { clear = false })

    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      group = under_cursor_highlights_group,
      desc = "Highlight references under the cursor",
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = under_cursor_highlights_group,
      desc = "Clear highlight references",
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })

    -- vim.api.nvim_create_autocmd("LspDetach", {
    --   buffer = bufnr,
    --   group = under_cursor_highlights_group,
    --   callback = function(event2)
    --     vim.lsp.buf.clear_references()
    --   end,
    -- })
  end
end

-- Diagnostic configuration.
vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    source = "if_many",
    format = function(diagnostic)
      local diagnostic_message = {
        [vim.diagnostic.severity.ERROR] = diagnostic.message,
        [vim.diagnostic.severity.WARN] = diagnostic.message,
        [vim.diagnostic.severity.INFO] = diagnostic.message,
        [vim.diagnostic.severity.HINT] = diagnostic.message,
      }
      return diagnostic_message[diagnostic.severity]
    end,
  },
  severity_sort = true,
  float = { source = "if_many" },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = {
    text = {
      -- requires nerd-fonts
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
})

-- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
local show_handler = vim.diagnostic.handlers.virtual_text.show
assert(show_handler)
local hide_handler = vim.diagnostic.handlers.virtual_text.hide
vim.diagnostic.handlers.virtual_text = {
  show = function(ns, bufnr, diagnostics, opts)
    table.sort(diagnostics, function(diag1, diag2)
      return diag1.severity > diag2.severity
    end)
    return show_handler(ns, bufnr, diagnostics, opts)
  end,
  hide = hide_handler,
}

-- Override the hover and signature help handlers to limit their size.
local hover = vim.lsp.buf.hover
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.hover = function()
  return hover({
    max_height = math.floor(vim.o.lines * 0.5),
    max_width = math.floor(vim.o.columns * 0.4),
  })
end

-- Override the signature help handler to limit its size.
local signature_help = vim.lsp.buf.signature_help
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.signature_help = function()
  return signature_help({
    max_height = math.floor(vim.o.lines * 0.5),
    max_width = math.floor(vim.o.columns * 0.4),
  })
end

-- Update mappings when registering dynamic capabilities e.g. for code actions.
local register_capability = vim.lsp.handlers[methods.client_registerCapability]
vim.lsp.handlers[methods.client_registerCapability] = function(err, res, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if not client then
    return
  end

  on_attach(client, vim.api.nvim_get_current_buf())

  return register_capability(err, res, ctx)
end

-- Create an autocommand to set up LSP keymaps when an LSP client attaches to a buffer.
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Configure LSP keymaps",
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if not client then
      return
    end

    on_attach(client, args.buf)
  end,
})

local function enable_lsp_servers()
  local server_configs = vim
    .iter(vim.api.nvim_get_runtime_file("lsp/*.lua", true))
    :map(function(file)
      return vim.fn.fnamemodify(file, ":t:r")
    end)
    :totable()
  vim.lsp.enable(server_configs)
  -- vim.lsp.buf.workspace_diagnostics()
end

-- Set up LSP servers (load before the first buffer is read).
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  once = true,
  callback = enable_lsp_servers,
})

-- Useful LSP commands.

vim.api.nvim_create_user_command("LspInfo", function()
  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  if #clients == 0 then
    vim.notify("No LSP clients attached to this buffer.", vim.log.levels.INFO)
    return
  end

  local client_names = vim
    .iter(clients)
    :map(function(client)
      return client.name
    end)
    :totable()

  vim.notify(("LSP clients attached to this buffer: %s"):format(table.concat(client_names, ", ")), vim.log.levels.INFO)
end, {
  desc = "Show LSP information for the current buffer",
})

vim.api.nvim_create_user_command("LspStart", function(_)
  enable_lsp_servers()
end, {
  nargs = "?",
  desc = "Start LSP server(s)",
})

vim.api.nvim_create_user_command("LspStop", function(opts)
  local clients = opts.fargs

  if #clients == 0 then
    clients = vim
      .iter(vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() }))
      :map(function(client)
        return client.name
      end)
      :totable()
  end

  for _, name in ipairs(clients) do
    if vim.lsp.config[name] == nil then
      vim.notify(("LSP server %s is not configured."):format(name))
    else
      vim.lsp.enable(name, false)
    end
  end
end, {
  nargs = "?",
  desc = "Stop LSP server(s)",
})

vim.api.nvim_create_user_command("LspRestart", function(opts)
  local clients = opts.fargs

  if #clients == 0 then
    clients = vim
      .iter(vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() }))
      :map(function(client)
        return client.name
      end)
      :totable()
  end

  for _, name in ipairs(clients) do
    if vim.lsp.config[name] == nil then
      vim.notify(("LSP server %s is not configured."):format(name))
    else
      vim.lsp.enable(name, true)
    end
  end
end, {
  nargs = "?",
  desc = "Restart LSP server(s)",
})
