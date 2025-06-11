---@type vim.lsp.Config
return {
  cmd = { "templ", "lsp" },
  filetypes = { "templ", "tmpl" },
  root_markers = { "go.mod", "go.work", ".git" },
}
