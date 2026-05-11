return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = { "rust" },
    -- `init` (not `config`): vim.g.rustaceanvim must exist before the plugin loads on FileType.
    init = function()
      vim.g.rustaceanvim = {
        server = {
          on_attach = function(_, bufnr)
            local function map(lhs, rhs, desc)
              vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
            end

            map("<leader>rr", "<cmd>RustLsp runnables<cr>", "Rust runnables")
            map("<leader>rd", "<cmd>RustLsp debuggables<cr>", "Rust debuggables")
            map("<leader>rm", "<cmd>RustLsp expandMacro<cr>", "Rust expand macro")
            map("<leader>rp", "<cmd>RustLsp parentModule<cr>", "Rust parent module")
            map("<leader>rc", "<cmd>RustLsp openCargo<cr>", "Rust open Cargo.toml")
            map("K", "<cmd>RustLsp hover actions<cr>", "Rust hover actions")
          end,
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              checkOnSave = true,
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              procMacro = { enable = true },
              inlayHints = {
                lifetimeElisionHints = { enable = "skip_trivial" },
              },
            },
          },
        },
      }
    end,
  },
  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {},
  },
}
