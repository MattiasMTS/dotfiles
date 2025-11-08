---@type vim.lsp.Config
return {
  cmd = { "cue", "lsp" },
  filetypes = { "cue" },
  root_markers = { "cue.mod", ".git" },
}
