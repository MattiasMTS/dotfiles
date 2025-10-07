---@type vim.lsp.Config
return {
  cmd = { "tofu-ls", "serve" },
  filetypes = { "opentofu", "opentofu-vars" },
  root_markers = { ".terraform", ".git" },
}
