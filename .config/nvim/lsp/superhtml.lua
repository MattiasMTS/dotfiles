---@type vim.lsp.Config
return {
  cmd = { "superhtml", "lsp" },
  filetypes = { "superhtml", "html" },
  root_markers = { ".git" },
  single_file_support = true,
}
