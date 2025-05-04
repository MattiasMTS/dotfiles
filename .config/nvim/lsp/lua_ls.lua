---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git", "stylua.toml" },
  settings = {
    Lua = {
      completion = { callSnippet = "Replace" },
      diagnostics = { globals = { "vim" }, disable = { "different-requires" } },
      format = { enable = false }, -- Using stylua for formatting.
      hint = {
        enable = true,
        arrayIndex = "Disable",
      },
      runtime = { version = "LuaJIT" }, -- cuz neovim uses LuaJIT
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library",
        },
      },
    },
  },
}
