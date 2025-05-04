---@type vim.lsp.Config
return {
  cmd = { "tflint", "--langserver" },
  filetypes = { "terraform", "terraform-vars" },
  root_markers = { ".terraform", ".git", "*.tfvars", ".tflint.hcl" },
}
