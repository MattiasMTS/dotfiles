---@type vim.lsp.Config
return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    "ruff.toml",
    ".ruff.toml",
    "uv.lock",
    ".git",
  },
  settings = {
    basedpyright = {
      analysis = { typeCheckingMode = "strict" },
    },
  },
}
