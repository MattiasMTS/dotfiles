---@type vim.lsp.Config
return {
  cmd = { "sqlmesh_lsp" },
  filetypes = { "sql", "python", "yaml", "yml" },
  root_markers = {
    "config.py",
    "config.yml",
    "config.yaml",
    ".sqlmesh",
    "pyproject.toml",
    ".git",
  },
  settings = {},
}
