---@type vim.lsp.Config
return {
  cmd = { "buf", "lsp", "serve", "--log-format=text" },
  filetypes = { "proto" },
  root_markers = { "buf.yaml", ".git" },
  reuse_client = function(client, config)
    -- `buf lsp serve` is meant to be used with multiple workspaces.
    return client.name == config.name
  end,
}
